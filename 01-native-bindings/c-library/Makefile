CC = gcc
CFLAGS = -Wall -Wextra

LIB = libcaesar.a

$(LIB): caesar.o
	ar rcs $(LIB) caesar.o

caesar.o: caesar.c caesar.h
	$(CC) $(CFLAGS) -c caesar.c -o caesar.o

clean:
	rm -f caesar.o $(LIB)
