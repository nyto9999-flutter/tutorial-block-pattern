/*All BloC classes will conform to this interface.
This interface doesn't do much except force you to
add a dispose method. But keep in mind with streams:
you have to close them when you don't need them anymore
or 'they can cause a memory leak The dispose method is
where the app will check for this' */
abstract class Bloc {
  void dispose();
}
