#!/bin/bash

###
# Добавляем данные
###

echo "Наполняем роутер тестовыми данными"
docker exec -it mongos_router mongosh --port 27020 --eval '
const db = db.getSiblingDB("somedb");
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
print("Всего документов = " + db.helloDoc.countDocuments());
exit();
'