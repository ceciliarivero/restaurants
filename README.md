Restaurants
===========

This is a website made with [Cuba](http://cuba.is) microframework (Ruby) and
[Redis](http://redis.io) database.

The purpose of developing this project is to learn how to create a website
using small but powerful tools.


How to start
------------

- Clone this repository.

- Install the gems listed in '.gems' or run 'gem install dep', then 'dep install' and let [dep](https://github.com/cyx/dep) do its job.

- Run 'shotgun' and head to 'localhost:9393' in your browser to see the
website working.

Note: to be able to log in as Admin, you'll have to create the corresponding
keys in Redis:

In Terminal:

- redis-cli
- HMSET Admin:1 "email" "admin@mail.com" "password" "7110eda4d09e062aa5e4a390b0a572ac0d2c0220"
 (That's "1234" encrypted).
- SET Admin:id "1"
- HMSET Admin:uniques:email "admin@mail.com" "1"
- SADD Admin:all "1"

To log in as Admin go to: 'localhost:9393/admin' and type:
Email: admin@mail.com
Password: 1234