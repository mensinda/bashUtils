#!/bin/bash

class BASHBinding
  private:
    -- libPath
    -- fifoDir

    -- isCompiled
    -- isStarted
    -- isInit

    -- bindingThread
    -- bbind_readReturnThread
    -- bbind_readCallbackThread

    :: bbind_readReturn
    :: bbind_readCallback

    :: bbind_generateFiles

    :: bbind_genCastFromChar
    :: bbind_genCast2Char

  protected:
    :: bbind_sendCALL
    :: bbind_sendReturn

  public:
    :: bbind_compile

    :: bbind_resolveTypedef

    :: bbind_start
    :: bbind_stop

    :: bbind_getIsInit

    :: BASHBinding
    :: ~BASHBinding
ssalc
