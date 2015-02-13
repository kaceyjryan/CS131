#! /bin/bash

javac BetterSorry.java
javac BetterSafe.java
javac UnsafeMemory.java

echo "Synchronized Test"
java UnsafeMemory Synchronized 8 10000 60 50 60 30 10 30

echo
echo "Unsynchronized Test"
java UnsafeMemory Unsynchronized 8 10000 60 50 60 30 10 30

echo
echo "GetNSet Test"
java UnsafeMemory GetNSet 8 10000 60 50 60 30 10 30

echo
echo "BetterSafe Test"
java UnsafeMemory BetterSafe 8 10000 60 50 60 30 10 30

echo
echo "BetterSorry Test"
java UnsafeMemory BetterSorry 8 10000 60 50 60 30 10 30

rm *.class
