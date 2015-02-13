#! /bin/bash

javac BetterSorry.java
javac BetterSafe.java
javac UnsafeMemory.java

echo "Synchronized"
java UnsafeMemory Synchronized 8 1000000 6 5 6 3 0 3

echo
echo "Unsynchronized"
java UnsafeMemory Unsynchronized 8 1000000 6 5 6 3 0 3

echo
echo "GetNSet"
java UnsafeMemory GetNSet 8 1000000 6 5 6 3 0 3

echo
echo "BetterSafe"
java UnsafeMemory BetterSafe 8 1000000 6 5 6 3 0 3

echo
echo "BetterSorry"
java UnsafeMemory BetterSorry 8 1000000 6 5 6 3 0 3

rm *.class
