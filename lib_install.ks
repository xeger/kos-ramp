function installIsPossible {
  PARAMETER namePattern is "[A-Za-z0-9].*[.]ks$".

  LIST FILES IN fls.
  LOCAL fSize is 0.

  FOR f IN fls {
    IF f:NAME:MATCHESPATTERN(namePattern) AND f:NAME:ENDSWITH(".ks") {
      SET fSize to fSize + f:SIZE.
    }
  }
  return (core:volume:freespace > fSize).
}

function installFiles {
  PARAMETER namePattern is "[A-Za-z0-9].*[.]ks$".

  LOCAL copyok is TRUE.
  LIST FILES IN fls.

  FOR f IN fls {
    IF f:NAME:MATCHESPATTERN(namePattern) AND f:NAME:ENDSWITH(".ks") {
      IF NOT COPYPATH(f,HD) { copyok OFF. }.
    }
  }

  RETURN copyok.
}
