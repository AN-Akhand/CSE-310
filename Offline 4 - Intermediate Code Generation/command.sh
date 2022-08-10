yacc -d -y -Wno-other -Wno-yacc -Wcounterexamples 1805089.y && g++ -w -c -o y.o y.tab.c 
flex 1805089.l && g++ -fpermissive -w -c  -o l.o lex.yy.c
g++ y.o l.o -lfl -o a.out
./a.out  in.txt 