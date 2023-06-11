#!/bin/bash


for i in {1..10}
do 
   username="user$i"
   password="user$i@@321"

   sudo useradd -m $username
   echo "$username:$password"

   echo "User $username created with password: $password"
done








OR



#!/bin/bash
for i in user{1..10}
do 
   useradd $i
   password $i"@@321"
echo $password | passwd $i --stdin
done