with Fabula.Main;

with Fasti_Steps;

--  The feature runner: Fabula.Main over the crate's step registry,
--  run over tests/features/ by `make features` and `alr test`.

procedure Fasti_Features is new
  Fabula.Main
    (Steps     => Fasti_Steps.Steps,
     Step_Defs => Fasti_Steps.Step_Defs,
     Hook_Defs => Fasti_Steps.Hook_Defs,
     Execute   => Fasti_Steps.Execute,
     Run_Hook  => Fasti_Steps.Run_Hook);
