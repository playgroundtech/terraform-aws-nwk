# v2.0.1

Internal refactoring of the module to comply with new standards.

FEATURES

ENHANCEMENTS

* Several tests added to the module.

BUG FIXES

# v2.0.0

The release contains breaking changes, be careful when you update your module
since it may involve downtime with a changed behavior of network traffic.

FEATURES

ENHANCEMENTS

* Complete rework of how we handle NAT Gateways.
  Now supports HA solutions and are deployed over all given availability zones.

* Added variable `nat_route_table` to make it possible to choose wether to
  create own route tables or let the module create them for you.

BUG FIXES

# v1.0.0

FEATURES

* Release of v1.0.0

ENHANCEMENTS

BUG FIXES
