package Mojolicious::Plugin::Entrypoint;

use Mojo::Base 'Mojolicious::Plugin';


sub register
{
	my($self, $app, $conf) = @_;
	
	my $controller = $app->controller_class;
	
	my $placeholder = $conf->{placeholder};
	
	$placeholder = 'entrypoint' unless $placeholder;
	
	if($app->routes->is_reserved($placeholder))
	{
		die "Test::Plugin::Entrypoint: placeholder '$placeholder' is reserved\n";
	}
	
	# Do nothing if subroutine is defined	

	return if $controller->can($placeholder);
	
	my $sub = sub
	{
		my $self = shift;
		
		my $pkg  = ref $self;
		
		my $entrypoint = $self->stash($placeholder);
		
		undef $entrypoint if $entrypoint eq $placeholder; # Prevent recursion
		
		undef $entrypoint if $entrypoint =~ /^_/;         # Skip private methods

		{
			no strict 'refs';
			
			no warnings;
			
			my $code = $pkg . '::' . $entrypoint;
			
			# Check if subroutine from self package 			
			
			unless(defined(*{$code}{CODE}))
			{
				return $self->render(status => 404, text => 'NOT FOUND');
			}
		}

		return $self->$entrypoint();
	};
	
	{ no strict 'refs';
	
		*{ "${controller}::${placeholder}" } = $sub;
	}
}


1;

