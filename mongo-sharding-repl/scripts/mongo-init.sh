#!/bin/bash

###
# Инициализируем и добавляем данные
###
echo "Инициализируем конфигурационный сервер mongosh"
docker exec -it configSrv mongosh --port 27017 --eval '
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
docker exec -it shard1 mongosh --port 27018 --eval '
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
       // { _id : 1, host : "shard2:27019" }
      ]
    }
);
exit();
'
echo "Инициализируем шард shard2"
docker exec -it shard2 mongosh --port 27019 --eval '
rs.initiate(
    {
      _id : "shard2",
      members: [
       // { _id : 0, host : "shard1:27018" },
        { _id : 1, host : "shard2:27019" }
      ]
    }
  );
exit();
'

echo "Инцициализируем роутер"
docker exec -it mongos_router mongosh --port 27020 --eval '

sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
exit();
'
echo "Наполняем роутер тестовыми данными"
docker exec -it mongos_router mongosh --port 27020 --eval '
const db = db.getSiblingDB("somedb");
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
print("Всего документов = " + db.helloDoc.countDocuments());
exit();
'

echo "Подсчет данных. Общее количество и по шардам"
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