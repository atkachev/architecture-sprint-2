#!/bin/bash

###
# Инициализируем и добавляем данные
###
echo "Инициализируем конфигурационный сервер mongosh"
docker exec -t configSrv mongosh --port 27017 --eval '
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
'

echo "Инициализируем шард shard1"
docker exec -t shard1_r1 mongosh --port 27018 --eval '
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_r1:27018", priority : 5 },
        { _id : 1, host : "shard1_r2:27021", priority : 3 },
        { _id : 2, host : "shard1_r3:27022", priority : 1 },
      ]
    }
);
exit();
'
echo "Инициализируем шард shard2"
docker exec -t shard2_r1 mongosh --port 27019 --eval '
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2_r1:27019" },
        { _id : 1, host : "shard2_r2:27023" },
        { _id : 2, host : "shard2_r3:27024" },
      ]
    }
  );
exit();
'

echo "Инцициализируем роутер"
docker exec -t mongos_router mongosh --port 27020 --eval '

sh.addShard( "shard1/shard1_r1:27018");
sh.addShard( "shard2/shard2_r1:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
exit();
'
echo "Наполняем роутер тестовыми данными"
docker exec -t mongos_router mongosh --port 27020 --eval '
const db = db.getSiblingDB("somedb");
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
print("Всего документов = " + db.helloDoc.countDocuments());
exit();
'

###
# Подсчет данных
###

echo "Подсчет данных. Общее количество"
docker exec -t mongos_router mongosh --port 27020 --eval '
const db = db.getSiblingDB("somedb");
print("Всего документов = " + db.helloDoc.countDocuments());
exit();
'
echo "Количество документов в shard1"
docker exec -t shard1_r1 mongosh --port 27018 --eval '
const db = db.getSiblingDB("somedb");
const members = db.adminCommand( { replSetGetStatus: 1 } ).members;
print("Количество реплик для шарда shard1 = " + members.length);
for(var i = 0; i < members.length; i++)
  print("Реплика информация: " + members[i].name + " " + members[i].stateStr);
print("Количество документов в shard1_r1 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -t shard1_r2 mongosh --port 27021 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1_r2 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -t shard1_r3 mongosh --port 27022 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard1_r3 = " + db.helloDoc.countDocuments());
exit();
'
echo "Количество документов в shard2"
docker exec -t shard2_r1 mongosh --port 27019 --eval '
const db = db.getSiblingDB("somedb");
const members = db.adminCommand( { replSetGetStatus: 1 } ).members;
print("Количество реплик для шарда shard2 = " + members.length);
for(var i = 0; i < members.length; i++)
  print("Реплика информация: " + members[i].name + " " + members[i].stateStr);
print("Количество документов в shard2_r1 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -t shard2_r2 mongosh --port 27023 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2_r2 = " + db.helloDoc.countDocuments());
exit();
'
docker exec -t shard2_r3 mongosh --port 27024 --eval '
const db = db.getSiblingDB("somedb");
print("Количество документов в shard2_r3 = " + db.helloDoc.countDocuments());
exit();
'

echo "Проверка времени выполнения запроса с кешированием и без. 5 раза подряд запускается curl"
for i in $(seq 1 5);
do
  curl -o /dev/null -s -w $i' попытка время='%{time_total}\\n -X 'GET' \
    'http://localhost:8080/helloDoc/users' \
    -H 'accept: application/json'
done