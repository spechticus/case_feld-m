.PHONY: check_dbt run_containers stop_containers setup 

dbt_shell:
	docker exec postgres:12.17 psql -h postgres -U postgres

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

setup: install_packages

install_packages: setup_pyenv
	pip install dbt-postgres
	@echo "assigning DBT_PROFILES_DIR"
	export DBT_PROFILES_DIR=$(CURDIR)

setup_pyenv:
	@echo "Setting up python environment..."
	python3 -m venv ./venv
	. venv/bin/activate
	@echo "Installing dependencies..."
