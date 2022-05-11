package Mojolicious::Plugin::Entrypoint;

use Mojo::Base 'Mojolicious::Plugin';


sub register
{
	my($self, $app, $conf) = @_;
	
	my $controller = $app->controller_class;
	
	my $action = $conf->{action};
	
	unless($action)
	{
		$action = 'entrypoint';
	}

	if($controller->can($action))
	{
		return;
	}
	
	my $sub = sub
	{
		my $self = shift;
		
		my $pkg  = ref $self;
		
		my $entrypoint = $self->stash($action);

		undef $entrypoint if $entrypoint eq $action; # Prevent recursion
		
		{
			no strict 'refs';
			
			no warnings;
			
			my $code = $pkg . '::' . $entrypoint;
			
			unless(defined(*{$code}{CODE}))
			{
				return $self->render(status => 404, text => 'NOT FOUND');
			}
		}

		return $self->$entrypoint();
	};
	
	{ no strict 'refs';
	
		*{ "${controller}::${action}" } = $sub;
	}
}


1;
