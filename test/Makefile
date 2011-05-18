CC= g++
LOCAL_LIBS= -lcityhash
OBJS= citymain.o
OUTPUT= city

city: citymain.o
	$(CC) $(LOCAL_LIBS) $(OBJS) -o $(OUTPUT)

clean:
	rm -f $(OUTPUT) $(OBJS)