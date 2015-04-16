#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"

#include "const-c.inc"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

extern FILE *stderr;

#ifdef WIN32

#include <windows.h>

#define CLOSESOCKET(q)		closesocket(q);
#define	ERR			WSAGetLastError()
#define SLEEP(q)		Sleep(q*1000)

#else  /* unix */

#include <unistd.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <netdb.h>

typedef	int		SOCKET;

#define	INVALID_SOCKET	-1
#define	SOCKET_ERROR	-1

#define CLOSESOCKET(q)		close(q);
#define	ERR			errno
#define SLEEP(q)		sleep(q)

#endif

#ifndef INT2PTR
   #define INT2PTR(any,d)  (any)(d)
   #define PTR2IV(p)       (IV)(p)
#endif

#ifdef _BIG_ENDIAN
	#define GET_LE_INT(x) ( (x & 0x000000FF)<<24 | (x & 0x0000FF00)<<8 | (x & 0x00FF0000)>>8 |(x & 0xFF000000)>>24 )
	#define GET_LE_SHORT(x) ( (x & 0x00FF)<<8 | (x & 0xFF00)>>8 )
#else
	#define GET_LE_INT(x) ( x )
	#define GET_LE_SHORT(x) ( x )
#endif /* BIG_ENDIAN */

unsigned char	_vn_send_term[]	= { 0xBA, 0xCB, 0xDC, 0xED };
unsigned char	_vn_recv_term[]	= { 0xAB, 0xBC, 0xCD, 0xDE };


class VNClient {
public:
	VNClient() {
		_vn_sock = 0;
		_vn_port = 0;

//		_vn_cookie = NEWSV(0, 20);
		_vn_cookie[0] = '9';
		_vn_cookie[1] = 0;
	}
	~VNClient() {
		_close_connection();
	}

	bool OpenConnection(char *addr, int port) {
		bool RETVAL = false;
		struct sockaddr_in mp_addr;
		long ready_addr;
		_close_connection();
		if(_vn_port != 0)
		{
			printf("Can't close connection\n");
			goto quit;
		}
		_vn_port = port;
 		if((_vn_sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
	 	{
			printf("Cannot create socket - %d\n", ERR);
			goto quit;
		}
		if((ready_addr = inet_addr(addr)) == INADDR_NONE)
		{
			struct hostent *he;
			if((he = gethostbyname(addr)) == NULL)
			{
				printf("Cannot resolve address - %s\n", addr);
				goto quit;
			}
//			ready_addr = (((char) he->h_addr[3]) << 24) + (((char) he->h_addr[2]) << 16) + (((char) he->h_addr[1]) << 8) + ((char) he->h_addr[0]);
			ready_addr = GET_LE_INT( *(int*)he->h_addr );
		}
		mp_addr.sin_family = AF_INET;
		mp_addr.sin_port = htons(port);
		mp_addr.sin_addr.s_addr = ready_addr;

		if((connect(_vn_sock, (const struct sockaddr*)&mp_addr, sizeof(mp_addr)) == SOCKET_ERROR))
		{
			_close_connection();
	//		CLOSESOCKET(_vn_sock);
	//		printf("Cannot connect: %d\n", ERR);
			fprintf(stderr, "Cannot connect: %d\n", ERR);
			goto quit;
		}
		
		RETVAL = true;
		quit:
		return RETVAL;

	}

	bool CheckConnection() {
		return (_vn_port == 0) ? 0 : 1;
	}

	void CloseConnection() {
		_close_connection();
	}

	void SetCookie(char *cookie) {
		strcpy(_vn_cookie, cookie);
	}

	void _close_connection()
	{
		if(_vn_port != 0)
		{
			CLOSESOCKET( _vn_sock );
			_vn_port = 0;
		}
	}


	int _recv_all(char *buf, int len)
	{
		SOCKET sock = _vn_sock;
		int offs = 0;
		struct sockaddr rem_addr;
		int addr_len = sizeof(rem_addr);
		int l;
	
		while(offs < len) {
			l = recv(sock, buf + offs, len - offs, 0);
			if ((l <= 0) && ERR) {
		           	printf("recv(): error - %d\n", ERR);
        		   	return 1;	/* ERROR - needs special handling */
	        	}
			offs += l;
		}
		return 0;
	}

	int _send_all(char *buf, int len)
	{
		SOCKET sock = _vn_sock;
		int offs = 0;
		int l;

		while(offs < len) {
			l = send(sock, buf + offs, len - offs, 0);
			if ((l <= 0) && ERR) {
//		           	printf("send(): error - %d\n", ERR);
	        	   	fprintf(stderr, "send(): error - %d\n", ERR);
				return 1;	/* ERROR - needs special handling */
			}
			offs += l;
		}
		return 0;
	}

	int _send_string(const char *str)
	{
		long l = strlen(str);
		unsigned char b[4];
//		b[0] = l & 255;	b[1] = (l >> 8) & 255; b[2] = (l >> 16) & 255; b[3] = (l >> 24) & 255;
		*(int*)b = GET_LE_INT( l );

		if(_send_all((char *) b, 4)) return 1;
		if(_send_all((char *) str, l)) return 1;

		return 0;
	}

	SOCKET	_vn_sock;
	int	_vn_port;
	char 	_vn_cookie[20];
};


/* ************************************************************************** 
 *  Network layer
 *
 ************************************************************************* */


/******************************************************************************************************************************************************/

MODULE = VN::Client		PACKAGE = VN::Client
INCLUDE: const-xs.inc

VNClient *
VNClient::new()

void
VNClient::DESTROY()

bool
VNClient::OpenConnection(addr, port)
	char *addr;
	int port;

bool
VNClient::CheckConnection()

void
VNClient::CloseConnection()

void
VNClient::SetCookie(cookie)
	char *cookie;


bool
Init()
	PREINIT:
#ifdef WIN32
	WSADATA winsock_data;
#endif
	CODE:
	RETVAL = FALSE;
#ifdef WIN32
	if (WSAStartup (0x0101, &winsock_data)) {
		printf("%d\n", WSAGetLastError());
		goto quit;
	}
#endif
	RETVAL = TRUE;
quit:
	OUTPUT:
	RETVAL


SV *
VNClient::Call(func, ...)
	char *func;
PREINIT:
	char *res = NULL;
	int i, j;
PPCODE:

	if(THIS->_vn_port == 0)
	{
		XPUSHs(sv_2mortal(newSVpv("", 0)));
		goto done;
	}

#	fprintf(stderr, "VN::Client::Call( '%s', ", func );
#	for(i = 2; i < items; i++) {
#		STRLEN len = 0;
#		char *tmp = SvPV(ST(i), len);
#		fprintf(stderr, "'%s', ", tmp );
#	}
#	fprintf(stderr, " )\n");

	if(THIS->_send_string(func)) {
#		fprintf(stderr, "FAILED: _send_string( %d, '%s')\n", THIS->_vn_sock, func);
		goto err;
	}
	if(THIS->_send_string(THIS->_vn_cookie)) {
#		fprintf(stderr, "FAILED: _send_string( %d, '%s')\n", THIS->_vn_sock, THIS->_vn_cookie);
		goto err;
	}
	for(i = 2; i < items; i++)
	{
		STRLEN len = 0;
		char *tmp = SvPV(ST(i), len);
		if(THIS->_send_string(tmp)) { 
#			fprintf(stderr, "FAILED: _send_string( %d, '%s')\n", THIS->_vn_sock, tmp);
			goto err;
		}
#		fprintf(stderr, "VNDriver::Call : sent '%s'\n", tmp );
	}

	if(THIS->_send_all((char *)_vn_send_term, 4)) goto err;

	for(;;) {
		unsigned char l[4];
		long len;
		if(THIS->_recv_all((char *)l, 4)) goto err;
		if(memcmp(l, _vn_recv_term, 4) == 0) break;
//		len = l[0] | (l[1] << 8) | (l[2] << 16) | (l[3] << 24);
		len = GET_LE_INT( *(int*)l );


		if(res != NULL) free(res);
		res = (char *)malloc(len + 1);

		if(THIS->_recv_all(res, len)) goto err;
		res[len] = 0;
	}

	XPUSHs(sv_2mortal(newSVpv(res, 0)));
	free(res);
	goto done;
err:
	THIS->_close_connection();
	XPUSHs(sv_2mortal(newSVpv("", 0)));
done:

