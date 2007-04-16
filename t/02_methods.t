# -*- Mode: Perl; -*-
package main;

no warnings;
use blib;
use Test::More tests => 77;
use IO::String;
use Data::Dumper;

use REST::Resource;
use REST::Request;


&main();
exit( 0 );

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_http;

sub	foo
{
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_param;

sub	http
{
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_header;

sub	http
{
}

sub	param
{
}


#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	good::derived_resource;

use blib;
use base "REST::Resource";

sub	unauthorized
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= 401;		## Unauthorized
    my( $data )		= undef;

    return( $status, $data );
}


#----------------------------------------------------------------------
#----------------------------------------------------------------------

package main;

#----------------------------------------------------------------------
sub	main
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";
    my( $cgi )		= new REST::Request();
    my( $restful )	= new REST::Resource( request_interface => $cgi );
    ok( defined( $restful ), "Constructor works via class name." );
    my( $RESTful )	= $restful->new();
    ok( defined( $RESTful ), "Construct works via instance." );

    &test_request_interface();
    &test_methods( $restful, $cgi );
    &test_formats( $restful, $cgi );
    &test_response( $restful, $cgi );
    &test_request( $cgi );
    &test_authentication( $cgi );
    &test_default_format_detection();
    &test_api_responses();
}




#----------------------------------------------------------------------
sub	test_methods
{
    my( $restful )	= shift;
    my( $cgi )		= shift;

    foreach my $method ("GET", "PUT", "POST", "DELETE")
    {
	ok( $restful->method( $method )		eq \&REST::Resource::unimplemented, "$method handler matches expectation" );
	ok( $restful->description( $method )	=~ /Unimplemented/, "$method description matches expectation" );
    }
    foreach my $method ("HEAD", "TRACE")
    {
	ok( $restful->method( $method )		eq \&REST::Resource::api, "$method handler matches expectation" );
	ok( $restful->description( $method )	=~ /discoverability/, "$method description matches expectation" );
    }
    ok( $restful->method( "authenticate" )	eq \&REST::Resource::authenticate, "authenticate handler matches expectation" );
    ok( $restful->description( "authenticate" )	=~ /Default no-authorization-required/, "authenticate description matches expectation" );


    &test_status( $restful, $cgi, "api", 200 );
    &test_status( $restful, $cgi, "authenticate", 200 );
    &test_status( $restful, $cgi, "unimplemented", 200 );
}





#----------------------------------------------------------------------
sub	test_formats
{
    my( $restful )	= shift;
    my( $cgi )		= shift;

    ok( $restful->format( "xml" )		eq \&REST::Resource::format_xml, "xml handler matches expectation" );
    ok( $restful->format( "application/xml" )	eq \&REST::Resource::format_xml, "application/xml handler matches expectation" );
    ok( $restful->format( "html" )		eq \&REST::Resource::format_html, "html handler matches expectation" );
    ok( $restful->format( "text/html" )		eq \&REST::Resource::format_html, "text/html handler matches expectation" );
    ok( $restful->format( "text" )		eq \&REST::Resource::format_text, "text handler matches expectation" );
    ok( $restful->format( "text/plain" )	eq \&REST::Resource::format_text, "text/plain handler matches expectation" );
    ok( $restful->format( "json" )		eq \&REST::Resource::format_json, "json handler matches expectation" );
    ok( $restful->format( "text/javascript" )	eq \&REST::Resource::format_json, "text/javascript handler matches expectation" );

    ok( ! defined( $restful->format( "non-existent" ) ), "non-existent handler matches expectation" );

    ok( $restful->description( "xml" ) =~ /xml/, "xml description matches expectation" );
    ok( $restful->description( "application/xml" ) =~ /Accept/, "application/xml description matches expectation" );
    ok( $restful->description( "html" ) =~ /html/, "html description matches expectation" );
    ok( $restful->description( "text/html" ) =~ /Accept/, "text/html description matches expectation" );
    ok( $restful->description( "json" ) =~ /json/, "json description matches expectation" );
    ok( $restful->description( "text/javascript" ) =~ /Accept/, "text/javascript description matches expectation" );

    $restful->format( "text/javascript", \&REST::Resource::format_json, "foo" );
    ok( $restful->description( "text/javascript" ) =~ /foo/, "text/javascript description matches expectation: " . $restful->description( "text/javascript" )  );

    ok( $restful->format_xml( $cgi, 200, { foo => "bar" } ) ne "", "format_xml() results match expectation." );
    ok( $restful->format_json( $cgi, 200, { foo => "bar" } ) ne "", "format_json() results match expectation." );
    ok( $restful->format_html( $cgi, 200, { foo => "bar" } ) ne "", "format_html() results match expectation." );

    $ENV{HTTP_ACCEPT}	= "application/xml, text/html, text/javascript, text/plain";
    ok( $restful->default_format( $cgi ) eq "application/xml", "Accept: application/xml; induced correct default format detection." );
    $ENV{HTTP_ACCEPT}	= "text/javascript, application/xml, text/html, text/plain";
    ok( $restful->default_format( $cgi ) eq "text/javascript", "Accept: text/javascript; induced correct default format detection." );
    $ENV{HTTP_ACCEPT}	= "text/html, application/xml, text/javascript, text/plain";
    ok( $restful->default_format( $cgi ) eq "text/html", "Accept: text/html; induced correct default format detection." );
    $ENV{HTTP_ACCEPT}	= "text/plain, text/html, application/xml, text/javascript";
    ok( $restful->default_format( $cgi ) eq "text/plain", "Accept: text/plain; induced correct default format detection." );

    $ENV{HTTP_ACCEPT}		= "text/xml, application/xml, application/xhtml+xml, text/html; q=0.9, text/plain; q=0.8, image/png, */*; q=0.5";
    $ENV{HTTP_USER_AGENT}	= "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.3) Gecko/20070309 Firefox/2.0.0.3";
    ok( $restful->default_format( $cgi ) eq "html", "Gecko browser defaults to html." );

    $ENV{HTTP_ACCEPT}		= "text/html; q=0.9, text/plain; q=0.8, image/png, */*; q=0.5";
    $ENV{HTTP_USER_AGENT}	= "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.3) Gecko/20070309 Firefox/2.0.0.3";
    ok( $restful->default_format( $cgi ) eq "text/html", "Gecko browser defaults to html." );

    $ENV{HTTP_ACCEPT}		= "text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1";
    $ENV{HTTP_USER_AGENT}	= "Opera/9.10 (X11; Linux i686; U; en)";
    ok( $restful->default_format( $cgi ) eq "text/html", "Opera browser defaults to html." );

    $ENV{HTTP_ACCEPT}		= "image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/vnd.ms-powerpoint, application/vnd.ms-excel, application/msword, */*";
    $ENV{HTTP_USER_AGENT}	= "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)";
    ok( $restful->default_format( $cgi ) eq "html", "MSIE browser defaults to html." );

    $ENV{HTTP_ACCEPT}		= "text/html, image/jpeg, image/png, text/*, image/*, */*";
    $ENV{HTTP_USER_AGENT}	= "Mozilla/5.0 (compatible; Konqueror/3.3; Linux) (KHTML, like Gecko)";
    ok( $restful->default_format( $cgi ) eq "text/html", "Konqueror browser defaults to html." . $restful->default_format( $cgi ) );



    $cgi->param( "format", "xml" );
    ok( $restful->default_format( $cgi ) eq "xml", "?format=xml; induced correct default format detection." );
    $cgi->param( "format", "json" );
    ok( $restful->default_format( $cgi ) eq "json", "?format=json; induced correct default format detection." );
    $cgi->param( "format", "html" );
    ok( $restful->default_format( $cgi ) eq "html", "?format=html; induced correct default format detection." );
    $cgi->param( "format", "text" );
    ok( $restful->default_format( $cgi ) eq "text", "?format=text; induced correct default format detection." );

}




#----------------------------------------------------------------------
sub	test_status
{
    my( $restful )	= shift;
    my( $cgi )		= shift;
    my( $method )	= shift;
    my( $expected )	= shift;

    my( $status, $data )	= $restful->$method( $cgi );
    ok( $status eq $expected, "Method [$method] returned status [$status], expected status [$expected]" );
}



#----------------------------------------------------------------------
sub	test_response
{
    my( $restful )	= shift;
    my( $cgi )		= shift;

    my( $io_string )	= new IO::String();
    my( $content )	= "";

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/plain";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\$VAR1/, "Data::Dumper output detected in text/plain response." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\$VAR1/, "JSON output detected in text/javascritp response." . $content );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\<html\>/, "HTML output detected in text/html response." . $content );

    $ENV{HTTP_ACCEPT}	= "q=1.0, application/xml";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\#REQUIRED/, "XML output detected in application/xml response." . $content );

    $ENV{REQUEST_METHOD}	= "blurfl";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\#REQUIRED/, "XML output detected in spite of bad REQUEST_METHOD." . $content );
}



#----------------------------------------------------------------------
sub	test_request
{
    my( $cgi )		= new REST::Request();

    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{bleech}	= "bar";
    $ENV{BLURFL}	= "BAR";
    ok( $cgi->http( "BLEECH" ) eq "bar", "Lowercase environment variable extraction." );
    ok( $cgi->http( "blurfl" ) eq "BAR", "Uppercase environment variable extraction." );
    ok( ! defined( $cgi->http( "Plugh" ) ), "Non-existent variable extraction." );

    $ENV{REQUEST_METHOD}= "PUT";
    $cgi		= new REST::Request();
    ok( $cgi->http( "REQUEST_METHOD" ) eq "PUT", "REQUEST_METHOD state change is undetectable, as expected." );

    $ENV{REQUEST_METHOD}= "DELETE";
    $cgi		= new REST::Request();
    ok( $cgi->http( "REQUEST_METHOD" ) eq "DELETE", "REQUEST_METHOD state change is undetectable, as expected." );

    $ENV{REQUEST_METHOD}= "GET";
    $cgi		= new REST::Request();
    ok( $cgi->http( "REQUEST_METHOD" ) eq "GET", "REQUEST_METHOD state change is undetectable, as expected." );

    $ENV{REQUEST_METHOD}= "POST";
    $cgi		= new REST::Request();
    ok( $cgi->http( "REQUEST_METHOD" ) eq "POST", "REQUEST_METHOD state change is undetectable, as expected." );
}



#----------------------------------------------------------------------
sub	test_request_interface
{
    &test_no_http();
    &test_no_param();
    &test_no_header();
}


#----------------------------------------------------------------------
sub	test_no_http
{
    eval
    {
	my( $cgi )	= bless( {}, "bad::request_no_http" );
	my( $restful )	= new REST::Resource( request_interface => $cgi );
    };
    if  ($@)
    {
	my( $e ) = $@;
	ok( $e =~ /does not implement/, "Expected exception thrown." );
    }
}



#----------------------------------------------------------------------
sub	test_no_param
{
    eval
    {
	my( $cgi )	= bless( {}, "bad::request_no_param" );
	my( $restful )	= new REST::Resource( request_interface => $cgi );
    };
    if  ($@)
    {
	my( $e ) = $@;
	ok( $e =~ /does not implement/, "Expected exception thrown." );
    }
}



#----------------------------------------------------------------------
sub	test_no_header
{
    eval
    {
	my( $cgi )	= bless( {}, "bad::request_no_header" );
	my( $restful )	= new REST::Resource( request_interface => $cgi );
    };
    if  ($@)
    {
	my( $e ) = $@;
	ok( $e =~ /does not implement/, "Expected exception thrown." );
    }
}



#----------------------------------------------------------------------
sub	test_authentication
{
    my( $cgi )		= shift;
    my( $io_string )	= new IO::String();
    my( $restful )	= new good::derived_resource();
    $restful->method( "authenticate", \&good::derived_resource::unauthorized, "401: Unauthorized behavior" );

    select( $io_string );
    $restful->handle_request( $cgi );
    ok( 1, "No failures executing handle_request with unauthorized behavior (weak test)." );
}







#----------------------------------------------------------------------
sub	test_default_format_detection
{
    my( $restful )	= new REST::Resource();
    my( $cgi )		= new REST::Request();
    $ENV{HTTP_ACCEPT}	= "q=1.0, application/xhtml+xml, application/xml";
    ok( $restful->default_format( $cgi ) eq "application/xml", "quality 1.0 application/xml default format detected." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, some/mimetype; q=0, other/mimetype";
    ok( $restful->default_format( $cgi ) eq "xml", "default xml default format presumed." );

    $ENV{HTTP_ACCEPT}	= "q=0.1, some/mimetype";
    ok( $restful->default_format( $cgi ) eq "xml", "default xml default format presumed." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/plain";
    ok( $restful->default_format( $cgi ) eq "text/plain", "quality 1.0 text/plain default format detected." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    ok( $restful->default_format( $cgi ) eq "text/html", "quality 1.0 text/html default format detected." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    ok( $restful->default_format( $cgi ) eq "text/javascript", "quality 1.0 text/javascript default format detected." );

    $ENV{HTTP_ACCEPT}	= undef;
    ok( $restful->default_format( $cgi ) eq "xml", "no accept header returns xml by default." );
}



#----------------------------------------------------------------------
sub	test_api_responses
{
    my( $restful )	= new REST::Resource();
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 443;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";
    delete $ENV{REQUEST_URI};

    my( $status, $data )	= $restful->api( new REST::Request() );
    ok( $data->{GET}->{url}	=~ /https\:/, 	"https semantics detected. " . Dumper( $data ) );
    ok( $data->{HEAD}->{url}	=~ /foo.pl/, 	"No-REQUEST_URI semantics detected. " . Dumper( $data ) );

    delete $ENV{SCRIPT_NAME};
    ( $status, $data )		= $restful->api( new REST::Request() );
    ok( $data->{GET}->{url}	=~ /dummy/, 	"/dummy/testing/uri detected. " . Dumper( $data ) );
}



1;

