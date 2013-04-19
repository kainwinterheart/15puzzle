#!/usr/bin/perl

use strict;

++$|;

use Carp ();

package Field;

use List::Util 'sum';

sub new
{
	my $v = shift;

	return bless( { @_ }, ( ref( $v ) or $v ) );
}

sub goal
{
	my $clone = shift -> clone();

	foreach my $point ( $clone -> all_points() )
	{
		my ( $gx, $gy ) = $point -> goal();

		$point -> x( $gx );
		$point -> y( $gy );

		$clone -> add_point( $point );
	}

	return $clone;
}

sub parent
{
	my $self = shift;

	if( scalar( @_ ) )
	{
		$self -> { 'parent' } = shift;
		$self -> recalc_h();
	}

	return $self -> { 'parent' };
}

sub points
{
	my $self = shift;

	if( scalar( @_ ) )
	{
		$self -> { 'points' } = shift;
	}

	return $self -> { 'points' } ||= [];
}

sub add_point
{
	my ( $self, $point ) = @_;

	( $self -> points() -> [ $point -> y() ] ||= [] ) -> [ $point -> x() ] = $point;
	$self -> { 'points_hash' } -> { $point -> data() } = $point;

	delete $self -> { 'h' };
	delete $self -> { 'all_points' };
	delete $self -> { 'as_string' };

	return 1;
}

sub get_point_by_coords
{
	my ( $self, $x, $y ) = @_;

	return undef if $x < 0;
	return undef if $y < 0;

	return $self -> points() -> [ $y ] -> [ $x ];
}

sub get_point_by_data
{
	my ( $self, $data ) = @_;

	return $self -> { 'points_hash' } -> { $data };

	foreach my $x ( @{ $self -> points() } )
	{
		foreach my $point ( @$x )
		{
			if( $point -> data() eq $data )
			{
				return $point;
			}
		}
	}

	return undef;
}

sub all_points
{
	my $self = shift;

	if( my $data = $self -> { 'all_points' } )
	{
		return @$data;
	}

	my @data = ();

	foreach my $x ( @{ $self -> points() } )
	{
		foreach my $point ( @$x )
		{
			push @data, $point;
		}
	}

	return @{ $self -> { 'all_points' } = \@data };
}

sub can_be_solved
{
	my $self  = shift;
	my $undef = $self -> get_point_by_data( '' );

	my $e     = $undef -> y() + 1;
	my $N     = 0;
	my @data  = $self -> all_points();

	for( my $i = 0; $i < scalar( @data ); ++$i )
	{
#		next if $data[ $i ] -> is_the_same( $undef );
#		next if $i == 0;

		for( my $j = ( $i + 1 ); $j < scalar( @data ); ++$j )
		{
			next if $data[ $j ] -> is_the_same( $undef );

			if( $data[ $j ] -> num() < $data[ $i ] -> num() )
			{
				++$N;
			}
		}
	}
# warn $e;
# warn $N;
	return ( ( ( $e + $N ) % 2 ) == 0 );
}

sub total_points
{
	return scalar( shift -> all_points() );
}

sub is_solved
{
	my $self = shift;

	return ( $self -> how_many_of_points_are_at_the_goal() == $self -> total_points() );
}

sub how_many_of_points_are_not_at_the_goal
{
	my $self = shift;

	return ( $self -> total_points() - $self -> how_many_of_points_are_at_the_goal() );
}

sub how_many_of_points_are_at_the_goal
{
	my $self = shift;
	my $cnt  = 0;

	foreach my $point ( $self -> all_points() )
	{
		++$cnt if $point -> is_at_goal();
	}

	return $cnt;
}

sub clone
{
	my $self  = shift;
	my $clone = $self -> new( %$self );

	delete $clone -> { 'points_hash' };
	delete $clone -> { 'points' };
	delete $clone -> { 'parent' };

	foreach my $point ( $self -> all_points() )
	{
		$clone -> add_point( $point -> clone() );
	}

	return $clone;
}

sub consume
{
	my ( $self, $field ) = @_;

	foreach my $his_point ( $field -> all_points() )
	{
		my $point = $self -> get_point_by_data( $his_point -> data() );

		$point -> x( $his_point -> x() );
		$point -> y( $his_point -> y() );

		$self -> add_point( $point );
	}

	$self -> parent( $field -> parent() );
	$self -> g( $field -> g() );
	$self -> h( $field -> h() );

	return 1;
}

sub recalc_g
{
	delete shift -> { 'g' };

	return 1;
}

sub g
{
	my $self = shift;

	unless( defined $self -> { 'g' } )
	{
#		$self -> { 'g' } = sum( map{ $_ -> manhattan_distance() } $self -> all_points() );
#		$self -> { 'g' } = 1;
		$self -> { 'g' } = 0;

#		my $dummy = $self;

#		while( $dummy = $dummy -> parent() )
#		{
#			++ $self -> { 'g' };
#		}
	}

	if( scalar( @_ ) )
	{
		$self -> { 'g' } = shift;
	}

	return $self -> { 'g' };
}

sub recalc_h
{
	delete shift -> { 'h' };

	return 1;
}

sub h
{
	my $self = shift;

	if( defined( my $h = $self -> { 'h' } ) )
	{
		return $h;
	}
# =item
	my $h    = $self -> how_many_of_points_are_not_at_the_goal();
	my @data = @{ $self -> points() };
	my $i    = scalar( @data );

	foreach my $x ( @data )
	{
		my $ok = 1;
#		my $c  = 0;

		foreach my $point ( @$x )
		{
			unless( $point -> is_at_goal() )
			{
				$ok = 0;
#				++$c;
				last;
			}
		}

		my $penalty = --$i;

		unless( $ok )
		{
#			$h += scalar( @data ) * $penalty;# * $c;
			$h += int( ( scalar( @data ) * $penalty ) / 2 );
#			$h += $penalty;
#			$h += $penalty * $c;
		}
	}
# =cut
	$h += sum( map{ $_ -> manhattan_distance() } $self -> all_points() );

#	if( 0 )
	{
		my $top   = undef;
		my $field = $self;

		while( $field = $field -> parent() )
		{
			$top = $field;
		}

		if( $top )
		{
#			my $d = 0;
#			my $c = 0;

			foreach my $initial_point ( $top -> all_points() )
			{
				my $point = $self -> get_point_by_data( $initial_point -> data() );

				$h += $point -> manhattan_distance( $initial_point -> x(), $initial_point -> y() );
#				if( my $ld = $point -> manhattan_distance( $initial_point -> x(), $initial_point -> y() ) )
#				{
#					$d += $ld;
#					++$c;
#				}
			}

#			$h += ( $d / $c );
		}
	}

	{
		foreach my $point ( $self -> all_points() )
		{
			foreach my $neighbor ( @{ $point -> neighbors( $self ) } )
			{
				my ( $gx, $gy ) = $point -> goal();
				my ( $his_gx, $his_gy ) = $neighbor -> goal();

				if( ( $gy == $his_gy ) and ( $gx == $neighbor -> x() ) and ( $his_gx == $point -> x() ) )
				{
					$h += scalar( @data );#( ( ( $neighbor -> neighbors( $self ) - 1 ) + ( $point -> neighbors( $self ) - 1 ) ) / 2 );
				}
			}
		}
	}

	return $self -> { 'h' } = $h;

#	return $self -> { 'h' } //= $self -> how_many_of_points_are_not_at_the_goal();
#	my $self = shift;

#	if( scalar( @_ ) )
#	{
#		$self -> { 'h' } = shift;
#	}

#	return $self -> { 'h' };
}

sub get_distance_to_field
{
	return 1;
	my ( $self, $field ) = @_;

	my $sum  = 0;
	my @data = ();

	foreach my $point ( @data = $self -> all_points() )
	{
		my $his_point = $field -> get_point_by_data( $point -> data() );

		$sum += $point -> manhattan_distance( $his_point -> x(), $his_point -> y() );
	}

	return $sum;
#	return $sum * 2;
#	return ( $sum / scalar( @data ) );
#	return ( $sum / ( scalar( @data ) / 2 ) );
#	return ( $sum / scalar( @{ $self -> points() } ) );
}

sub recalc_f
{
	my $self = shift;

	$self -> recalc_g();
	$self -> recalc_h();

	return 1;
}

sub f
{
#	return shift -> h();
	my $self = shift;

	return ( abs( $self -> g() ) + abs( $self -> h() ) );
}

sub as_string
{
	my $self = shift;

	return join( ',', map{ $_ -> data() or '_' } $self -> all_points() );
}

sub as_string2
{
	my $self = shift;

	if( my $str = $self -> { 'as_string' } )
	{
		return $str;
	}

	my $str  = '';

	foreach my $x ( @{ $self -> points() } )
	{
		foreach my $point ( @$x )
		{
			$str .= sprintf( '%s', ( $point -> num() or '_' ) );
			$str .= "\t";
		}

		$str .= "\n";
	}

	return $self -> { 'as_string' } = $str;
}

sub is_the_same
{
	my ( $self, $field ) = @_;

	return ( $self -> as_string() eq $field -> as_string() );
}

package Point;

sub manhattan_distance
{
	my ( $self, $to ) = @_;

	my ( $gx, $gy ) = ( ( ref( $to ) eq 'ARRAY' ) ? @$to : $self -> goal() );

	return ( abs( $gx - $self -> x() ) + abs( $gy - $self -> y() ) );
}

sub clone
{
	my $self = shift;

	return $self -> new( %$self );
}

sub new
{
	my $v = shift;

	return bless( { @_ }, ( ref( $v ) or $v ) );
}

sub skip
{
	my $self = shift;

	return ( $self -> is_at_goal() and ( ( $self -> y() == 0 ) ) );# or ( $self -> y() == 1 ) ) );
}

sub path  { shift -> num() eq '' }
sub data  { shift -> { 'data' } }
sub num   { shift -> data() }

sub is_at_goal
{
	my $self = shift;

	my ( $gx, $gy ) = $self -> goal();

	return ( ( $self -> x() == $gx ) and ( $self -> y() == $gy ) );
}

sub goal
{
	my $num = shift -> num();

	return ( 3 )x2 if $num eq '';

	return ( ((($num%4)or 4)-1), (int($num/4)+(($num%4)?1:0)-1) );
}

sub moved
{
	my $self = shift;

	if( scalar( @_ ) )
	{
		$self -> { 'moved' } = shift;
	}

	return $self -> { 'moved' };
}

sub x
{
	my $self = shift;

	if( scalar( @_ ) )
	{
		$self -> { 'x' } = shift;
	}

	return $self -> { 'x' };
}

sub y
{
	my $self = shift;

	if( scalar( @_ ) )
	{
		$self -> { 'y' } = shift;
	}

	return $self -> { 'y' };
}

sub neighbors
{
	my ( $self, $map ) = @_;

	my @out    = ();
	my @points = (
		[ $self -> x(), ( $self -> y() + 1 ) ],
		[ $self -> x(), ( $self -> y() - 1 ) ],
		[ ( $self -> x() + 1 ), $self -> y() ],
		[ ( $self -> x() - 1 ), $self -> y() ]
	);

#	print $self -> num() . "...\n";

	while( my $point = shift @points )
	{
#		if( my $match = $map -> { $point -> [ 0 ] } -> { $point -> [ 1 ] } )
		if( my $match = $map -> get_point_by_coords( $point -> [ 0 ], $point -> [ 1 ] ) )
		{
#			print $match -> num() . "...\n";
			push @out, $match;
		}
	}

	@out = sort{ rand( time() ) <=> rand( time() ) } @out;

	return \@out;
}

sub is_the_same
{
	my ( $self, $point ) = @_;

	if( ( $self -> x() == $point -> x() ) and ( $self -> y() == $point -> y() ) )
	{
		return 1;
	}

	return 0;
}

package a_star;

use List::Util ( 'min', 'sum' );

sub new
{
	my $v = shift;

	my $self = bless( { @_ }, ( ref( $v ) or $v ) );

	$self -> { 'start_time' } = time();

	return $self;
}

sub closedset
{
	my $self = shift;

#	if( scalar( @_ ) )
#	{
#		$self -> { 'closedset' } = shift;
#	}

	$self -> { 'closedset' } ||= [];

#	&Carp::confess unless scalar( keys %{ $self -> { 'closedset_hash' } } ) == scalar( @{ $self -> { 'closedset' } } );

	return $self -> { 'closedset' };
}

sub openset
{
	my $self = shift;

	if( 0 )
	{
		my $s1 = scalar( keys %{ $self -> { 'openset_hash' } } );
		my $s2 = sum( map{ scalar( @{ $self -> { 'openset_hash_f' } -> { $_ } } ) } keys %{ $self -> { 'openset_hash_f' } } );

		&Carp::confess( sprintf( '%d != %d', $s1, $s2 ) ) unless $s1 == $s2;
	}

	return [ map{ @{ $self -> { 'openset_hash_f' } -> { $_ } } } sort{ $a <=> $b } keys %{ $self -> { 'openset_hash_f' } } ];

#	if( scalar( @_ ) )
#	{
#		$self -> { 'openset' } = shift;
#	}

#	return $self -> { 'openset' } ||= [];
}

sub get
{
	my $self = shift;
#	my $best = undef;
#	my @moar = ();

#	my $cnt = scalar( @{ $self -> openset() } );

	die unless defined( my $min_f = $self -> { 'min_f' } ); # min( keys %{ $self -> { 'openset_hash_f' } } );

#	@{ $self -> { 'openset_hash_f' } -> { $min_f } } = sort{ $a -> g() <=> $b -> g() } @{ $self -> { 'openset_hash_f' } -> { $min_f } };

	my $best  = shift @{ $self -> { 'openset_hash_f' } -> { $min_f } };
=item
	while( my $candidate = shift @{ $self -> openset() } )
	{
		if( defined $best )
		{
			if( $candidate -> f() < $best -> f() )
			{
				push @moar, $best;

				$best = $candidate;
			} else
			{
				push @moar, $candidate;
			}

		} else
		{
			$best = $candidate;
		}
	}

	unshift @{ $self -> openset() }, @moar;
=cut
	if( $best )
	{
		delete $self -> { 'openset_hash' } -> { $best -> as_string() };
	}

	unless( scalar( @{ $self -> { 'openset_hash_f' } -> { $min_f } } ) )
	{
		delete $self -> { 'openset_hash_f' } -> { $min_f };
		$self -> { 'min_f' } = min( keys %{ $self -> { 'openset_hash_f' } } );
	}

#	&Carp::confess if $best and $self -> is_open( $best );
#	&Carp::confess if $best and $self -> is_closed( $best );

#	&Carp::confess if $best and not( scalar( @{ $self -> openset() } ) == ( $cnt - 1 ) );

	return $best;
}

sub get_open
{
	my ( $self, $field ) = @_;

	return $field = $self -> { 'openset_hash' } -> { $field -> as_string() };

	foreach my $lfield ( @{ $self -> { 'openset_hash_f' } -> { $field -> f() } } )
	{
		if( $lfield -> is_the_same( $field ) )
		{
			return $lfield;
		}
	}

	&Carp::confess;
}

sub replace_open
{
	my ( $self, $field ) = @_;

	if( my $old = $self -> get_open( $field ) )
	{
#		my $cnt = scalar( @{ $self -> openset() } );

		delete $self -> { 'openset_hash' } -> { $old -> as_string() };
#warn $old -> as_string();
#warn $field -> as_string();
		foreach my $f ( ( $old -> f() ) )#, $field -> f() ) )
		{
			@{ $self -> { 'openset_hash_f' } -> { $f } } = grep{ not $_ -> is_the_same( $old ) and not $_ -> is_the_same( $field ) } @{ $self -> { 'openset_hash_f' } -> { $f } };

			unless( scalar( @{ $self -> { 'openset_hash_f' } -> { $f } } ) )
			{
				delete $self -> { 'openset_hash_f' } -> { $f };
				$self -> { 'min_f' } = min( keys %{ $self -> { 'openset_hash_f' } } );
			}
		}

		$old -> consume( $field );

		$self -> open( $old );

#		&Carp::confess unless $cnt == scalar( @{ $self -> openset() } );

		return 1;
	}

	return 0;
}

sub open
{
	my ( $self, $field ) = @_;

#	&Carp::confess if $self -> is_open( $field );

#	my $s1 = scalar( keys %{ $self -> { 'openset_hash' } ||= {} } );
#	my $s2 = scalar( @{ $self -> { 'openset_hash_f' } -> { $field -> f() } ||= [] } );

	my $f = undef;

	$self -> { 'openset_hash' } -> { $field -> as_string() } = $field;
	push @{ $self -> { 'openset_hash_f' } -> { ( $f = $field -> f() ) } }, $field;

	if( not( defined $self -> { 'min_f' } ) or ( $self -> { 'min_f' } > $f ) )
	{
		$self -> { 'min_f' } = $f;
	}

#	&Carp::confess unless scalar( keys %{ $self -> { 'openset_hash' } } ) == ( $s1 + 1 );
#	&Carp::confess unless scalar( @{ $self -> { 'openset_hash_f' } -> { $field -> f() } } ) == ( $s2 + 1 );

	return 1;
}

sub close
{
	my ( $self, $field ) = @_;

#	&Carp::confess if $self -> is_closed( $field );

	push @{ $self -> closedset() }, $field;

	$self -> { 'closedset_hash' } -> { $field -> as_string() } = 1;

	return 1;
}

sub is_closed
{
	my ( $self, $candidate ) = @_;

	return exists $self -> { 'closedset_hash' } -> { $candidate -> as_string() };

#	foreach my $point ( @{ $self -> closedset() } )
#	{
#		if( $point -> is_the_same( $candidate ) )
#		{
#			return 1
#		}
#	}

	return 0;
}

sub is_open
{
	my ( $self, $candidate ) = @_;

	return exists $self -> { 'openset_hash' } -> { $candidate -> as_string() };

#	foreach my $point ( @{ $self -> openset() } )
#	{
#		if( $point -> is_the_same( $candidate ) )
#		{
#			return 1
#		}
#	}

	return 0;
}

sub act2
{
	my ( $self, $field ) = @_;

	$self -> open( $field );

	if( 0 )
	{
		my $field = $field;

		while( $field = $field -> parent() )
		{
			$self -> close( $field );
		}
	}

#	my $total = 0;

	while( my $field = $self -> get() )
	{
#		$field -> recalc_g();
#		++$total;
#		print '-'x80 . "\n";
#		print $field -> as_string();
		print STDERR sprintf( 'g: %d, h: %d, open: %d, closed: %d, time: %d', $field -> g(), $field -> h(), scalar( @{ $self -> openset() } ), scalar( @{ $self -> closedset() } ), ( time() - $self -> { 'start_time' } ) );
#		printf( 'g: %d, total: %d', $field -> g(), $total );
		print STDERR ' 'x20;
		print STDERR "\r";
#		print "\n";

		if( 0 )
		{
			my $dummy = <>;
		}

		next if $self -> is_closed( $field );
		$self -> close( $field );

#		warn $field -> as_string();
		return $field if $field -> is_solved();

#		unless( $field -> can_be_solved() )
#		{
#			print "\nskip\n";
#			die;
#			next;
#			return;
#		}

		my $oundef = undef;
#my @pids = ();
		foreach my $neighbor ( @{ ( $oundef ||= $field -> get_point_by_data( '' ) ) -> neighbors( $field ) } )
		{
#			warn $neighbor -> num();
#			next if $self -> is_closed( $neighbor );
#			next unless $neighbor -> path();
#			next if $point -> num() eq $neighbor -> num();
#my $pid = fork();
#if( $pid == 0 )
#{
#exit 0;
#} else
#{
#push @pids, $pid;
#}
			my $new_field = $field -> clone();

#			$new_field -> recalc_g();
#			my $tentative_g_score   = ( $field -> g() + $new_field -> g() );
#			my $tentative_f_score   = ( $tentative_g_score + $new_field -> h() );
#			my $tentative_g_score   = $new_field -> g();
#			my $tentative_is_better = 0;

			my $undef = $new_field -> get_point_by_coords( $oundef -> x(), $oundef -> y() );
			my $point = $new_field -> get_point_by_coords( $neighbor -> x(), $neighbor -> y() );

			my $ox = $undef -> x();
			my $oy = $undef -> y();

			$undef -> x( $point -> x() );
			$undef -> y( $point -> y() );

			$point -> x( $ox );
			$point -> y( $oy );

			$new_field -> add_point( $point );
			$new_field -> add_point( $undef );

			next if $self -> is_closed( $new_field );

#			unless( $new_field -> can_be_solved() )
#			{
#				print "\n";
#				print $new_field -> as_string();
#				print &Data::Dumper::Dumper( $new_field );
#				die;
#				$self -> close( $new_field );

#				next;
#			}

			my $tentative_g_score   = ( abs( $field -> g() ) + abs( $field -> get_distance_to_field( $new_field ) ) ) * 1;
#			my $tentative_g_score   = ( abs( $field -> get_distance_to_field( $new_field ) ) * 1 );

			if( $self -> is_open( $new_field ) )
			{
				if( $tentative_g_score < $self -> get_open( $new_field ) -> g() )
#				if( $tentative_f_score < $self -> get_open( $new_field ) -> f() )
				{
					$new_field -> g( $tentative_g_score );
					$new_field -> parent( $field );
#					$new_field -> recalc_h();

					&Carp::confess unless $self -> replace_open( $new_field );
#					$tentative_is_better = 1;
				}

			} else
			{
				$new_field -> g( $tentative_g_score );
				$new_field -> parent( $field );

				$self -> open( $new_field );
#				$tentative_is_better = 1;
			}

#			if( $tentative_is_better )
#			{
#			}

#			if( my $rv = $self -> new() -> act2( $new_field ) )
#			{
#				return $rv;
#			}
# exit 0;
		}
#		wait for @pids;
	}

	return undef;
}

sub act
{
	my ( $self, $goal, $prev, $map ) = @_;

	while( my $point = $self -> get() )
	{
#		print $point -> num() . "...\n";

		return $point if $point -> is_at_goal();

		foreach my $neighbor ( @{ $point -> neighbors( $map ) } )
		{
			next if $self -> is_closed( $neighbor );
			next unless $neighbor -> path();
			next if $point -> num() eq $neighbor -> num();
#			next if exists $point -> { 'moves' } -> { $neighbor -> x() } -> { $neighbor -> y() };
#			next if $neighbor -> skip();# and $prev and ( $neighbor -> num() > $prev -> num() );

			my $tentative_g_score   = ( $point -> g() + &pathfinding::do::estimate_distance( $point, $neighbor, $map ) );
			my $tentative_is_better = 0;

			if( $self -> is_open( $neighbor ) )
			{
				if( $tentative_g_score < $neighbor -> g() )
				{
					$tentative_is_better = 1;
				}

			} else
			{
				$self -> open( $neighbor );
				$tentative_is_better = 1;
			}
# print $point -> num() . ' <=> ' . $neighbor -> num() . ': ' . $tentative_g_score . "\n";
			if( $tentative_is_better )
			{
				$neighbor -> g( $tentative_g_score );
				$neighbor -> h( &pathfinding::do::how_many_of_points_are_no_at_the_goal( $map ) ); # estimate_distance( $neighbor, $goal, $map ) );

				my $ox = $point -> x();
				my $oy = $point -> y();

				$point -> x( $neighbor -> x() );
				$point -> y( $neighbor -> y() );

				$neighbor -> x( $ox );
				$neighbor -> y( $oy );

				$point -> moved( 1 );
				$neighbor -> moved( 1 );

				$map -> { $point -> x() } -> { $point -> y() } = $point;
				$map -> { $neighbor -> x() } -> { $neighbor -> y() } = $neighbor;

				if( $point -> { 'moves_tick' } >= 1 )
				{
					delete $point -> { 'moves' };
					delete $point -> { 'moves_tick' };
				}

				$point -> { 'moves' } -> { $ox } -> { $oy } = 1;
				$point -> { 'moves_tick' } ++;
			}
		}
	}

	return undef;
}

package pathfinding::do;

my $field = Field -> new();

{
my @map = (
  [ 12, 1, 3,  5  ],
  [ '', 6, 7,  13 ],
  [ 11, 8, 15, 14 ],
  [ 2,  9, 10,  4 ]
#	[ '', '15', '14', '13' ],
#	[ '12', '11', '10', '9' ],
#	[ '8', '7', '6', '5' ],
#	[ '4', '3', '2', '1' ]
#	[ '0', 'X', '', '', '' ],
#	[ '', 'X', '', '', '' ],
#	[ '', '', '', 'X', '' ],
#	[ '', '', 'X', 'S', '' ],
#	[ '', '', '', 'X', '' ],
#	[ '', '', '', '', '' ]
);

{
	my $str = shift @ARGV;

	chomp $str;

	if( $str )
	{
		my $x = 0;
		my $y = 0;

		foreach my $point ( split( /,/, $str ) )
		{
			$map[ $y ] -> [ $x ] = ( sprintf( '%d', $point ) or '' );

			if( ++$x == 4 )
			{
				$x = 0;
				++$y;
			}
		}
# warn $x;
# warn $y;
		die 'wut' unless $x == 0 and $y == 4;
	}
}

my $x = 0;
my $y = 0;

foreach my $row ( @map )
{
	$x = 0;

	foreach my $col ( @$row )
	{
		$field -> add_point( Point -> new(
			x    => $x,
			y    => $y,
			data => $col
		) );

		++$x;
	}

	++$y;
}
}

# print Dumper($field);
# print 'can_be_solved: ' . ( $field -> can_be_solved() ? 1 : 0 ) . "\n";
# print Dumper( a_star -> new() -> act2( $field ) );
{
#	print "field:\n";
#	print $field -> as_string();
#	print "goal:\n";
#	print $field -> goal() -> as_string();

	die 'cannot be solved' unless $field -> can_be_solved();

	$field -> g( 0 );

	if( my $field = a_star -> new() -> act2( $field ) )
	{
		print STDERR "\n";
#		print "solved:\n";
#		print $field -> as_string();
		my @path = ( $field );

		while( $field = $field -> parent() )
		{
			unshift @path, $field;
		}

		while( my $field = shift @path )
		{
#			print STDERR $field -> as_string2();
#			print STDERR "\n";
			print $field -> as_string();
			print "\n";
		}
	}
}
exit 0;
my %map=();

foreach my $point ( $field -> all_points() )
{
	$map{ $point -> x() } -> { $point -> y() } = $point;
}

use Data::Dumper 'Dumper';

my %oks = ();
my %as  = ();

while(scalar(keys %oks)!=16)
{
my $nomoves = 1;
my $prev = undef;
foreach my $x ( sort{ rand( time() ) <=> rand( time() ) } keys %map )
#foreach my $x ( keys %map )
{
	foreach my $y ( sort{ rand( time() ) <=> rand( time() ) } keys %{ $map{ $x } } )
#	foreach my $y ( keys %{ $map{ $x } } )
	{
		my $point = $map{ $x } -> { $y };
		delete $as{ $point -> num() };
		MOVE: {
		my $obj = undef;

		unless( exists $as{ $point -> num() } )
		{
			$obj = $as{ $point -> num() } = a_star -> new();

			$obj -> open( $point );
		}

		$obj ||= $as{ $point -> num() };

		my ( $gx, $gy ) = $point -> goal();

		if( my $goal = $map{ $gx } -> { $gy } )
		{
#			print $point -> num()."...\n";
#			next if exists $oks{ $point -> num() } and ( ( $goal -> y() == 0 ) or ( $goal -> y() == 1 ) ) and $point -> is_at_goal();
#			next if $point -> skip();

			$point -> h( &how_many_of_points_are_no_at_the_goal( \%map ) ); # &estimate_distance( $point, $goal, \%map ) );
			$point -> g( 0 );

			$point -> moved( 0 );

			$obj -> act( $goal, ( $prev ? ( $prev -> is_the_same( $point ) ? undef : $prev ) : undef ), \%map );

			if( $point -> moved() )
			{
				$prev = $point;
				if( 0 )
				{
					printf( 'moved point num: "%s", gx: %d, gy: %d', $point -> num(), $gx, $gy );
					my $dummy = <>;
				}
				$nomoves = 0;
#				print Dumper( $point );
				my %rmap  = ();
				foreach my $x ( keys %map )
				{
					foreach my $y ( keys %{ $map{ $x } } )
					{
						$rmap{ $y } -> { $x } = $map{ $x } -> { $y };
					}
				}

				print '-'x80 . "\n";

				foreach my $y ( sort{ $a <=> $b } keys %rmap )
				{
					foreach my $x ( sort{ $a <=> $b } keys %{ $rmap{ $y } } )
					{
						printf( "%s\t", ( $rmap{ $y } -> { $x } -> num() or '_' ) );
					}

					print "\n";
				}

			if( $point -> is_at_goal() )
			{
				$oks{ $point -> num() } = 1;
			} else
			{
				delete $oks{ $point -> num() };

				redo MOVE;
			}
			}

		} else
		{
			printf( 'no goal, num: "%s", gx: %d, gy: %d', $point -> num(), $gx, $gy );
			print "\n";
		}
		};
	}
}
if($nomoves)
{
	print "unsolvable\n";
	last;
}
}

print Dumper( \%oks );

sub move
{
	my ( $last, $move, $queue, $map ) = @_;

	my $moved  = 0;

	foreach my $point ( @{ $last -> neighbors( $map ) } )
	{
		next if $point -> skip();

		my $omove = $queue -> { $point -> x() } -> { $point -> y() };

		if( not( defined $omove ) or ( $move < $omove ) )
		{
			$queue -> { $point -> x() } -> { $point -> y() } = $move;
			move( $point, $move + 1, $queue, $map );
		}
	}

	return 1;
}

sub estimate_distance
{
	my ( $start, $end, $map ) = @_;

	my %queue = ( $end -> x() => { $end -> y() => 0 } );

	move( $end, 1, \%queue, $map );

	my %moves = ();

	foreach my $x ( keys %queue )
	{
		foreach my $y ( keys %{ $queue{ $x } } )
		{
			$moves{ $queue{ $x } -> { $y } } -> { $x } = $y;
		}
	}

	return $queue{ $start -> x() } -> { $start -> y() };
}

sub how_many_of_points_are_no_at_the_goal
{
	my $map = shift;
	my $cnt = 0;

	foreach my $x ( keys %$map )
	{
		foreach my $y ( keys %{ $map{ $x } } )
		{
			unless( $map{ $x } -> { $y } -> is_at_goal() )
			{
				++$cnt;
			}
		}
	}

	return $cnt;
}

exit 0;


