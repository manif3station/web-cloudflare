package Cloudflare::Cookie;

use Dancer2 appname => 'Web';

post qr/.*/ => sub {
    my $params = params;
    $params->{__cf_chl_tk} or pass;
    forward request->path, $params, {method => 'GET'};
};

1;
