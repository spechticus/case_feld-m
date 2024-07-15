SHELL := /bin/bash
.PHONY: check_dbt run_containers stop_containers setup clean


clean: 
	@echo "Cleaning up dbt directories"
	dbt clean
	@echo "Cleaning up dbt containers"
	@docker ps -a --filter "name=dbt-run" --format "{{.ID}}" | xargs docker rm -f

enter_psql:
	@docker exec -it postgres psql -h postgres -U postgres postgres

build_dbt:
	docker-compose --project-name feldm_case run dbt build

snapshot:
	docker-compose --project-name feldm_case run dbt snapshot $(SELECTION)

test_dbt:
	docker-compose --project-name feldm_case run dbt test $(SELECTION)

run_dbt:
	docker-compose --project-name feldm_case run dbt run $(SELECTION)

load_rawdata:
	python3 raw_data/load_raw_data.py

check_dbt:
	@echo "running dbt debug"
	-dbt debug
	@echo "running dbt debug for the container version"
	docker-compose --project-name feldm_case run dbt debug

run_containers:
	docker-compose --project-name feldm_case up -d

stop_containers:
	docker-compose --project-name feldm_case down

setup:
	@echo "Setting up python environment..."
	python3.11 -m venv ./venv
	bash -c "source ./venv/bin/activate"
	. venv/bin/activate
	pip3.11 install -r requirements.txt
	@echo "assigning DBT_PROFILES_DIR"
	export DBT_PROFILES_DIR=$(CURDIR)
	docker-compose --project-name feldm_case run dbt deps
