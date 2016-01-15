#!/bin/bash

class BASHBinding
  private:
    -- bbind_libPath
    -- bbind_execPath
    -- bbind_fifoDir

    -- bbind_isCompiled
    -- bbind_isStarted
    -- bbind_isInit

    -- bbind_bindingThread
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
    -- bbind_option_useGDB

    :: bbind_compile

    :: bbind_resolveTypedef

    :: bbind_start
    :: bbind_stop

    :: bbind_getIsInit
    :: bbind_getIsCompiled

    :: BASHBinding
    :: ~BASHBinding
ssalc
