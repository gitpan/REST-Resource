# -*- Mode: Perl; -*-
package main;

no warnings "redefine";
use blib;
use Test::More tests => 13;
use IO::String;
use Data::Dumper;

use CGI::Fast;
use REST::Resource;
use REST::RequestFast;

&main();
exit( 0 );

#----------------------------------------------------------------------
#----------------------------------------------------------------------

package Mock::CGI;

use base "REST::RequestFast";

our( $requests )	= undef;

sub	new
{
    my( $class ) = "Mock::CGI";
    if  (defined( $requests ))
    {
	if  ($requests-- > 0)
	{
	    return( $class->SUPER::new( {'dinosaur'	=> 'barney',
					 'song'		=> 'I love you',
					 'friends'	=> [qw/Jessica George Nancy/] }
					) );
	}
	else
	{
	    return( undef );
	}
    }
    else
    {
	$requests = shift || 5;
	return( $class->SUPER::new( {'dinosaur'	=> 'barney',
				     'song'		=> 'I love you',
				     'friends'	=> [qw/Jessica George Nancy/] }
				    ) );
    }
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	Rest::Test1;

use blib;
use base "REST::Resource";

sub	ttl
{
    return( 2 );
}

sub	my_responder
{
    my( $cgi )		= shift;
    my( $status )	= 404;
    my( $data )		= $cgi;

    return( $status, $data )
}

sub	authenticate
{
    my( $cgi )		= shift;
    my( $status )	= 401;
    my( $data )		= $cgi;

    return( $status, $data );
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------

package	Rest::Test2;

use blib;
use base "REST::Resource";

sub	ttl
{
    return( 2 );
}

sub	browserprint
{
    my( $this )	= shift;
    $this->format_html( @_ );
}

sub	my_responder
{
    my( $cgi )		= shift;
    my( $status )	= 200;
    my( $data )		= $cgi;

    return( $status, $data )
}

sub	authenticate
{
    my( $cgi )		= shift;
    my( $status )	= 200;
    my( $data )		= $cgi;

    return( $status, $data );
}
#----------------------------------------------------------------------
#----------------------------------------------------------------------

package main;

#----------------------------------------------------------------------
sub	main
{
    &test_request();
    &test_new();
    &test_run();
}

#----------------------------------------------------------------------
sub	test_new
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";
    my( $cgi )		= new Mock::CGI( 1 );
    ok( defined( $cgi ), "Constructor works via class name." );
}




#----------------------------------------------------------------------
sub	test_run
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";

    $Mock::CGI::requests = 14;
    my( $cgi )		= new Mock::CGI(1);
    my( $restful )	= new Rest::Test1( request_interface => $cgi );
    $restful->method( "PUT", \&Rest::Test1::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    my( $start )	= time();
    my( $io_string )	= new IO::String();
    select( $io_string );
    $restful->run();
    my( $end )		= time();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "DELETE";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= new Rest::Test2( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "DELETE", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "GET";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= new Rest::Test2( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "GET", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= $restful->new( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "POST", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    delete $ENV{HTTP_ACCEPT};
    $cgi		= new Mock::CGI(1);
    $restful		= $restful->new( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test1::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "POST", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );
}


#----------------------------------------------------------------------
sub	test_request
{
    $Mock::CGI::requests = 14;

    my( $cgi )		= new Mock::CGI(1);
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{bleech}	= "bar";
    $ENV{BLURFL}	= "BAR";
    ok( $cgi->http( "BLEECH" ) eq "bar", "Lowercase environment variable extraction." );
    ok( $cgi->http( "blurfl" ) eq "BAR", "Uppercase environment variable extraction." );
    ok( ! defined( $cgi->http( "Plugh" ) ), "Non-existent variable extraction." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "PUT";
    $cgi		= new Mock::CGI(3);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "PUT", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "DELETE";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "DELETE", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "GET";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "GET", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "POST", "REQUEST_METHOD state change is undetectable, as expected." );
}



1;
