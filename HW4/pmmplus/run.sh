#! /bin/bash

clear

javac BetterSorry.java
javac BetterSafe.java
javac UnsafeMemory.java

echo "Synchronized"
java UnsafeMemory Synchronized 16 1000000 10 20 30 40 50

echo
echo "Unsynchronized"
java UnsafeMemory Unsynchronized 16 1000000 10 20 30 40 50

echo
echo "GetNSet"
java UnsafeMemory GetNSet 16 1000000 10 20 30 40 50

echo
echo "BetterSafe"
java UnsafeMemory BetterSafe 16 1000000 10 20 30 40 50

echo
echo "BetterSorry"
java UnsafeMemory BetterSorry 16 1000000 10 20 30 40 50

rm *.class
