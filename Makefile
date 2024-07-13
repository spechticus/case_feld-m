.PHONY: check_dbt run_containers stop_containers setup clean


clean: 
	dbt clean
	@docker ps -a --filter "name=dbt-run" --format "{{.ID}}" | xargs docker rm -f

enter_psql:
	@docker exec -it postgres psql -h postgres -U postgres postgres

build_dbt:
	docker-compose --project-name feldm_case run dbt build

test_dbt:
	docker-compose --project-name feldm_case run dbt test

run_dbt:
	docker-compose --project-name feldm_case run dbt run

check_dbt:
	@echo "running dbt debug"
	dbt debug

run_containers:
	docker-compose --project-name feldm_case up -d

stop_containers:
	docker-compose --project-name feldm_case down


setup:
	@echo "Setting up python environment..."
	python3 -m venv ./venv
	pip install -r requirements.txt
	. venv/bin/activate
	@echo "assigning DBT_PROFILES_DIR"
	export DBT_PROFILES_DIR=$(CURDIR)
	docker-compose --project-name feldm_case run dbt deps
