enum NamibianRegions {
  erongo("Erongo"),
  hardap("Hardap"),
  karas("Karas"),
  kavangoEast("Kavango East"),
  kavangoWest("Kavango West"),
  khomas("Khomas"),
  kunene("Kunene"),
  ohangwena("Ohangwena"),
  omaheke("Omaheke"),
  omusati("Omusati"),
  oshana("Oshana"),
  oshikoto("Oshikoto"),
  otjozondjupa("Otjozondjupa"),
  zambezi("Zambezi");

  const NamibianRegions(this.displayName);
  final String displayName;
}

enum IdType {
  namibianId("Namibian ID"),
  passport("Passport Number");

  const IdType(this.displayName);
  final String displayName;
}
