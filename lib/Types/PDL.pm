package Types::PDL;

# ABSTRACT: PDL types using Type::Tiny

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use Type::Library -base,
  -declare => qw[
    Piddle
    Piddle1D
    Piddle2D
    Piddle3D

    PiddleFromAny
  ];


use Types::Standard -types, 'is_Int';
use Type::Utils;
use Type::TinyX::Facets;
use String::Errf 'errf';
use B qw(perlstring);


declare_coercion PiddleFromAny,
  from Any,
  q[ do { local $@;
          require PDL::Core;
          my $new = eval { PDL::Core::topdl( $_ )  };
          $@ ? $_ : $new
     }
  ];


facet 'empty', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{empty};
    errf '%{not}s%{var}s->isempty',
      { var => $var, not => ( !!delete( $o->{empty} ) ? '' : '!' ) };
};

facet 'null', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{null};
    errf '%{not}s%{var}s->isnull',
      { var => $var, not => ( !!delete( $o->{null} ) ? '' : '!' ) };
};

facet ndims => sub {
    my ( $o, $var ) = @_;

    my %o = map { ( $_ => delete $o->{$_} ) }
      grep { exists $o->{$_} } qw[ ndims ndims_min ndims_max ];

    return unless keys %o;

    croak( "'$_' must be an integer\n" )
      for grep { !is_Int( $o{$_} ) } keys %o;


    if ( exists $o{ndims_max} and exists $o{ndims_min} ) {

        if ( $o{ndims_max} < $o{ndims_min} ) {
            croak( "'ndims_min' must be <= 'ndims_max'\n" );
        }

        elsif ( $o{ndims_min} == $o{ndims_max} ) {

            croak(
                "cannot mix 'ndims' facet with either 'ndims_min' or 'ndims_max'\n"
            ) if exists $o{ndims};

            $o{ndims} = delete $o{ndims_min};
            delete $o{ndims_max};
        }
    }

    my @code;

    if ( exists $o{ndims_max} or exists $o{ndims_min} ) {

        if ( exists $o{ndims_min} ) {

            push @code, errf '%{var}s->ndims >= %{value}i',
              {
                var   => $var,
                value => delete $o{ndims_min} };
        }

        if ( exists $o{ndims_max} ) {

            push @code, errf '%{var}s->ndims <= %{value}i',
              {
                var   => $var,
                value => delete $o{ndims_max} };
        }
    }

    elsif ( exists $o{ndims} ) {

        push @code, errf '%{var}s->ndims == %{value}i',
          { var => $var, value => delete $o{ndims} };
    }

    else {
        return;
    }

    croak( "cannot mix 'ndims' facet with either 'ndims_min' or 'ndims_max'\n" )
      if keys %o;

    return join( ' and ', @code );
};


facetize qw[ empty null ndims ], class_type Piddle, { class => 'PDL' };

facetize qw[ empty ],
  declare Piddle1D,
  as Piddle[ ndims => 1];

facetize qw[ empty ],
  declare Piddle2D,
  as Piddle[ ndims => 2];

facetize qw[ empty ],
  declare Piddle3D,
  as Piddle[ ndims => 3];

1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

  use Types::PDL -types;
  use Type::Params qw[ validate ];
  use PDL;

  validate( [ pdl ], Piddle );

=head1 DESCRIPTION

This module provides L<Type::Tiny> compatible types for L<PDL>.

=head2 Types

Types which accept parameters (see L</Parameters>) will list them.

=head3 C<Piddle>

Allows an object blessed into the class C<PDL>, e.g.

  validate( [pdl], Piddle );

It accepts the following parameters:

  null
  empty
  ndims
  ndims_min
  ndims_max

=head3 C<Piddle1D>

Allows an object blessed into the class C<PDL> with C<ndims> = 1.
It accepts the following parameters:

  empty

=head3 C<Piddle2D>

Allows an object blessed into the class C<PDL> with C<ndims> = 2.
It accepts the following parameters:

  empty

=head3 C<Piddle3D>

Allows an object blessed into the class C<PDL> with C<ndims> = 3.
It accepts the following parameters:

  empty

=head2 Coercions

The following coercions are provided, and may be applied via a type object's
L<Type::Tiny/plus_coercions> or L<Type::Tiny/plus_fallback_coercions> methods,
e.g.

  Piddle->plus_coercions( PiddleFromAny );

=head3 C<PiddleFromAny>

Uses L<PDL::Core/topdl> to coerce the value into a piddle.


=head2 Parameters

Some types take optional parameters which add additional constraints on
the object.  For example, to indicate that only empty piddles are accepted:

  validate( [pdl], Piddle[ empty => 1 ] );

The available parameters are:

=head3  C<empty>

This accepts a boolean value; if true the piddle must be empty
(i.e. the C<isempty> method returns true), if false, it must not be
empty.

=head3  C<null>

This accepts a boolean value; if true the piddle must be a null piddle, if false, it must not be
null.

=head3 C<ndims>

This specifies a fixed number of dimensions which the piddle must have. Don't mix use this
with C<ndims_min> or C<ndims_max>.

=head3 C<ndims_min>

The minimum number of dimensions the piddle may have. Don't specify this with C<ndims>.


=head3  C<ndims_max>

The maximum number of dimensions the piddle may have. Don't specify this with C<ndims>.


=head1 SEE ALSO

