RELEASE=$(shell git rev-parse HEAD)-$(shell date  +"%Y-%m-%d-%H-%M-%S")
POD=$(shell kubectl get pods | grep sheepdog | grep Running | awk '{print $$1}' | head -n 1)
SHA1=$(shell git rev-parse --short HEAD)-$(shell date +"%H-%M-%S")
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

kubeconfig:
	KUBECONFIG=./kubeconfig aws --profile opszero eks update-kubeconfig --name opszero

release:
	aws --profile opszero ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 451305228097.dkr.ecr.us-west-2.amazonaws.com
	docker buildx build --platform linux/amd64 --push -t 451305228097.dkr.ecr.us-west-2.amazonaws.com/opszero:$(RELEASE) .
	KUBECONFIG=./kubeconfig aws eks --profile opszero update-kubeconfig --name opszero
	helm upgrade --install opszero ./charts/opszero --set image.tag=$(RELEASE) -f ./charts/production.yaml

local-db-load:
	# ops-prod dumpdata --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 2 > /tmp/dump.json
	POSTGRES_HOST=0.0.0.0 REDIS_URL=redis://cache:6379/1 poetry run ./manage.py loaddata "/tmp/dump.json"

up:
	docker compose up --build --force-recreate

runserver-system6-prod:
	BRAND=system6 ops-prod runserver 0.0.0.0:8999

runserver-opszero-prod:
	BRAND=opszero ops-prod runserver 0.0.0.0:8090

runserver-abhiandcorrie-prod:
	BRAND=abhiandcorrie ops-prod runserver 0.0.0.0:8091

runserver-yerracapital-prod:
	BRAND=yerracapital ops-prod runserver 0.0.0.0:8092

runserver-abhiyerra-prod:
	BRAND=abhiyerra ops-prod runserver 0.0.0.0:8093

runserver-makeprospect-prod:
	BRAND=makeprospect ops-prod runserver 0.0.0.0:8089

runserver-yerraco-prod:
	BRAND=yerraco ops-prod runserver 0.0.0.0:8094

runserver-postswarm-prod:
	BRAND=postswarm ops-prod runserver 0.0.0.0:8095

runserver-climate-prod:
	BRAND=climate ops-prod runserver 0.0.0.0:8096

runserver-opszero:
	POSTGRES_HOST=0.0.0.0 REDIS_URL=redis://cache:6379/1 BRAND=opszero poetry run ./manage.py runserver 0.0.0.0:8086

runserver-abhiyerra:
	POSTGRES_HOST=0.0.0.0 BRAND=abhiyerra poetry run ./manage.py runserver 0.0.0.0:8084

runserver-yerracapital:
	POSTGRES_HOST=0.0.0.0 BRAND=yerracapital poetry run ./manage.py runserver 0.0.0.0:8085

runserver-abhiandcorrie:
	POSTGRES_HOST=0.0.0.0 BRAND=abhiandcorrie poetry run ./manage.py runserver 0.0.0.0:8087

runserver-suryaproperties:
	POSTGRES_HOST=0.0.0.0 BRAND=suryaproperties poetry run ./manage.py runserver 0.0.0.0:8088

runserver-goodoverall:
	POSTGRES_HOST=0.0.0.0 BRAND=goodoverall poetry run ./manage.py runserver 0.0.0.0:8089

makemigrations:
	POSTGRES_HOST=0.0.0.0 poetry run ./manage.py makemigrations --merge
	POSTGRES_HOST=0.0.0.0 poetry run ./manage.py makemigrations
	$(MAKE) migrate

migrate:
	POSTGRES_HOST=0.0.0.0 poetry run ./manage.py migrate

down:
	docker compose down --remove-orphans

test:
	POSTGRES_HOST=0.0.0.0 REDIS_URL=redis://cache:6379/1 poetry run coverage run --source='.' manage.py test \
		opszero.cloud \
		opszero.capital
	POSTGRES_HOST=0.0.0.0 REDIS_URL=redis://cache:6379/1 poetry run coverage report --omit="*migration*"

pre-commit-install:
	poetry run pre-commit install

pre-commit-uninstall:
	poetry run pre-commit uninstall

pre-commit:
	poetry run pre-commit run --all-files

build-and-deploy-opszero:
	DJANGO_ENV=production BRAND=opszero ./manage.py distill-local --exclude-staticfiles --force ./opszero-static
	npx wrangler pages publish ./opszero-static --project-name=opszero --commit-dirty=true

prod-psql:
	PGPASSWORD=h2qLUqJcZmD psql -h 0.0.0.0 -p 5431 -U opszero opszero_v6_production

flower-prod:
	kubectl port-forward deployments/opszero-celery-flower 5556:5555

celery-up:
	kubectl scale --replicas=4 deployments/opszero-celery

celery-down:
	kubectl scale --replicas=1 deployments/opszero-celery

prod-ssh:
	kubectl exec -it deployments/opszero-opszero -- bash

prod-shell:
	kubectl exec -it deployments/opszero-opszero -- ./manage.py shell

celery-purge:
	kubectl exec -it deployments/opszero-opszero -- celery -A opszero.celery purge
