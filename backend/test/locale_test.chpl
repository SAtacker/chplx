writeln("This program is running on ", numLocales, " locales");

var thisLocale = here.id;
writeln("This locale ID is: ", thisLocale);


var thisLocale2 = here.id;
writeln("This locale ID is: ", thisLocale2);

var thisLocale3 = here.id;

var x: int = here.id;

var b: int;
b = here.id;
writeln("This locale ID is: ", b);

writeln("This locale ID is: ", x);

var MyLocaleArray: [0..numLocales] locale =
      for i in 0..numLocales do Locales[(i)%numLocales];

forall loc in Locales {
   writeln("This locale ID is: ", here.id);
}

for loc in Locales {
   writeln("This locale ID is: ", here.id);
}

coforall loc in Locales {
   writeln("This locale ID is: ", here.id);
}