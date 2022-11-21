use strict;

use Test::More;
use FindBin '$Bin';

require "$Bin/../bin/cloudflare-tunnel";

my @events;
my $config;
my @args;

*CloudFlareTunnel::login = sub { push @events, 'login' };

*CloudFlareTunnel::create_web_tunnel =
  sub { push @events, 'create_web_tunnel' };

*CloudFlareTunnel::create_config =
  sub { $config = $_[0]; push @events, "create_config"; };

*CloudFlareTunnel::enable_tunnel_feature = sub {
    push @events, 'enable_tunnel_feature';
};

*CloudFlareTunnel::call_tunnel = sub { @args = @_; push @events, 'call_tunnel' };

subtest 'first time' => sub {
    @events = ();

    local *CloudFlareTunnel::list_tunnels =
      sub { push @events, 'list_tunnel'; return '' };

    eval { CloudFlareTunnel::main('register') };

    like $@, qr/Run again to continue/;

    is_deeply \@events, [
        qw(
          list_tunnel
          login
          create_web_tunnel
        )
    ];
};

subtest 'continue ...' => sub {
    @events = ();

    local *CloudFlareTunnel::list_tunnels = sub {
        push @events, 'list_tunnel';
        return q{
You can obtain more detailed information for each tunnel with `cloudflared tunnel info <name/uuid>`
ID                                   NAME        CREATED              CONNECTIONS  
2d56eb8f-bf4f-4f8e-928e-2c127d67c4d4 Web         2022-05-18T04:38:23Z 2xIAD, 2xORD 
2022-11-21T13:05:22Z WRN Your version 2022.7.0 is outdated. We recommend upgrading it to 2022.11.0
        };
    };

    CloudFlareTunnel::main('register');

    like $config, qr/2d56eb8f-bf4f-4f8e-928e-2c127d67c4d4/;

    is_deeply \@events, [
        qw(
          list_tunnel
          create_config
          enable_tunnel_feature
        )
    ];
};

subtest 'multiple tunnels ...' => sub {
    local *CloudFlareTunnel::list_tunnels = sub {
        push @events, 'list_tunnel';
        return q{
You can obtain more detailed information for each tunnel with `cloudflared tunnel info <name/uuid>`
ID                                   NAME        CREATED              CONNECTIONS  
2d56eb8f-bf4f-4f8e-928e-2c127d67c4d4 Web         2022-05-18T04:38:23Z 2xIAD, 2xORD 
1d56eb8f-bf4f-4f8e-928e-2c127d67c4d3 API         2022-05-18T04:38:23Z 2xIAD, 2xORD 
2022-11-21T13:05:22Z WRN Your version 2022.7.0 is outdated. We recommend upgrading it to 2022.11.0
        };
    };

    my $input;

    local *CloudFlareTunnel::get_input = sub { push @events, 'input'; $input };

    subtest 'typo of the tunnel id' => sub {
        @events = ();
        $input  = 'ABC';

        eval { CloudFlareTunnel::main('register') };
        like $@, qr/Invalid selection/;
        is_deeply \@events, [
            qw(
              list_tunnel
              input
            )
        ];
    };

    subtest 'typo of the tunnel id' => sub {
        @events = ();
        $config = '';
        $input = '1d56eb8f-bf4f-4f8e-928e-2c127d67c4d3';

        CloudFlareTunnel::main('register');

        like $config, qr/$input/;

        is_deeply \@events, [
            qw(
              list_tunnel
              input
              create_config
              enable_tunnel_feature
            )
        ];
    };
};

subtest 'call tunnel command' => sub {
    @events = ();

    my @expected = qw( x y z );

    CloudFlareTunnel::main(@expected);

    is_deeply \@events, ['call_tunnel'];

    is_deeply \@args, \@expected;
};

done_testing;
