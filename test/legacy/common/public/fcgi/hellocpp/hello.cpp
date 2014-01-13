#include <iostream>
#include "fcgio.h"

using namespace std;

int main(void) {
        // Backup the stdio streambufs
    streambuf * cin_streambuf  = cin.rdbuf();
    streambuf * cout_streambuf = cout.rdbuf();
    streambuf * cerr_streambuf = cerr.rdbuf();

    FCGX_Request request;

    FCGX_Init();
    FCGX_InitRequest(&request, 0, 0);

    int current = 0;
        
    while (FCGX_Accept_r(&request) == 0) {
        fcgi_streambuf cin_fcgi_streambuf(request.in);
        fcgi_streambuf cout_fcgi_streambuf(request.out);
        fcgi_streambuf cerr_fcgi_streambuf(request.err);

        cin.rdbuf(&cin_fcgi_streambuf);
        cout.rdbuf(&cout_fcgi_streambuf);
        cerr.rdbuf(&cerr_fcgi_streambuf);

        cout << "Content-type: text/html\r\n"
        << "\r\n"
        << "<html>\n"
        << "<head>\n"
        << "<title>Hello, C++ FCGI World!</title>\n"
        << "</head>\n"
        << "<body>\n"
        << "<h1>Hello, World!</h1>\n"
        << "<p>Current request number: <strong>" << ++current << "</strong></p>\n"
        // << "<p>STDIN: <strong>" << (char *)&cin_fcgi_streambuf << "</strong></p>\n"
        << "</body>\n"
        << "</html>\n";

        // Note: the fcgi_streambuf destructor will auto flush

    }

    // restore stdio streambufs
    cin.rdbuf(cin_streambuf);
    cin.rdbuf(cout_streambuf);
    cin.rdbuf(cerr_streambuf);

    return 0;

}

