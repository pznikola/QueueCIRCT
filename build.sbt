val defaultVersions = Map("chisel3" -> "3.6.0")

name := "QueueCIRCT"
scalaVersion := "2.13.10"
scalacOptions := Seq("-deprecation", "-feature", "-language:reflectiveCalls")
Test / scalacOptions ++= Seq("-language:reflectiveCalls")

libraryDependencies ++= Seq("chisel3").map {
  dep: String => "edu.berkeley.cs" %% dep % sys.props.getOrElse(dep + "Version", defaultVersions(dep))
}
libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play-json" % "2.9.2"
)
addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % defaultVersions("chisel3") cross CrossVersion.full)
resolvers ++= Seq(
  Resolver.sonatypeRepo("snapshots"),
  Resolver.sonatypeRepo("releases"),
  Resolver.mavenLocal
)

lazy val tapeout = (project in file("./tools/barstools/"))