/*
 *	@author Andrea Tassotti
 */
#include <unistd.h>

int usleep(useconds_t usec);

int main(int argc, char *argv[])
{
	if ( argc > 1 )
	{
		useconds_t usecs = atoll(argv[1]);
		usleep(usecs);
	}
}

