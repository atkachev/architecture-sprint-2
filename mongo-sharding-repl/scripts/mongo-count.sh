#!/bin/bash

###
# Подсчет данных
###

echo "Подсчет данных. Общее количество"
docker exec -it mongos_router mongosh --port 27020 --eval '
const db = db.getSiblingDB("somedb");
print("Всего документов = " + db.helloDoc.countDocuments());
exit();
'

echo "Количество документов в shard1"
docker exec -it shard1 mongosh --port 27018 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1 = " + db.helloDoc.countDocuments());
exit();
'

echo "Количество документов в shard2"
docker exec -it shard2 mongosh --port 27019 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2 = " + db.helloDoc.countDocuments());
exit();
'