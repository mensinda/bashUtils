#!/bin/bash

class BASHBinding
  private:
    -- libPath
    -- fifoDir

    -- isCompiled
    -- isStarted

    -- bindingThread
    -- readReturnThread
    -- readCallbackThread

    :: readReturn
    :: readCallback
    :: generateFiles

    :: genCastFromChar
    :: genCast2Char

  public:
    :: compileIfNeeded

    :: resolveTypedef

    :: start
    :: stop

    :: BASHBinding
    :: ~BASHBinding
ssalc
