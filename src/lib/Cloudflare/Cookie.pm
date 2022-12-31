package Cloudflare::Cookie;

use Dancer2 appname => 'Web';

post qr/.+/ => sub {
    params->{__cf_chl_tk} or pass;
    redirect request->path;
};

1;
