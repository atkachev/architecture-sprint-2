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
docker exec -it shard1_r1 mongosh --port 27018 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1_r1 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -it shard1_r2 mongosh --port 27021 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1_r2 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -it shard1_r3 mongosh --port 27022 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1_r3 = " + db.helloDoc.countDocuments());
exit();
'
echo "Количество документов в shard2"
docker exec -it shard2_r1 mongosh --port 27019 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2_r1 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -it shard2_r2 mongosh --port 27023 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2_r2 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -it shard2_r3 mongosh --port 27024 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2_r3 = " + db.helloDoc.countDocuments());
exit();
'