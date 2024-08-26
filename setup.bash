#!/bin/bash

set -e

echo "Выберите фреймворк для генерации кода:"
echo "1. Flask (Python)"
echo "2. Spring Boot (Java)"
echo "3. Node.js (Express)"
read -p "Введите номер вашего выбора: " choice

sudo apt-get update
sudo apt-get install -y docker.io openjdk-11-jdk wget jq python3 python3-venv maven nodejs npm

if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker
    sudo systemctl enable docker
fi

docker pull openapitools/openapi-generator-cli

cat <<EOL > task-api.yaml
openapi: 3.0.0
info:
  title: Task Management API
  version: 1.0.0
paths:
  /tasks:
    get:
      summary: Get list of tasks
      responses:
        '200':
          description: A list of tasks
          content:
            application/json:
              schema:
                type: array
                items:
                  \$ref: '#/components/schemas/Task'
components:
  schemas:
    Task:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        completed:
          type: boolean
EOL

case $choice in
    1)
        docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate \
            -i /local/task-api.yaml \
            -g python-flask \
            -o /local/generated-server

        python3 -m venv myenv
        source myenv/bin/activate
        pip install fastapi==0.100.1 uvicorn==0.23.0

        cat <<EOL > main.py
from fastapi import FastAPI

app = FastAPI()

tasks = [
    {"id": 1, "name": "Task 1", "completed": False},
    {"id": 2, "name": "Task 2", "completed": True},
]

@app.get("/tasks")
async def get_tasks():
    return tasks
EOL

        uvicorn main:app --host 0.0.0.0 --port 8000 --reload
        ;;
    2)
        docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate \
            -i /local/task-api.yaml \
            -g spring \
            -o /local/generated-server

        cd generated-server
        mvn spring-boot:run
        ;;
    3)
        docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate \
            -i /local/task-api.yaml \
            -g nodejs-express-server \
            -o /local/generated-server

        cd generated-server
        npm install
        npm start
        ;;
    *)
        echo "Неверный выбор. Пожалуйста, выберите один из предложенных вариантов."
        exit 1
        ;;
esac

echo "Процесс завершен успешно."
