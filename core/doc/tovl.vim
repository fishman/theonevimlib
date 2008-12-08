*tovl.txt*	For Vim version 7.2.

==============================================================================

            ---------------------------------------
                         TOVL (The one vimlib)
            ---------------------------------------

  !First of all: I need your help to make this a big success!

==============================================================================
1. Contents						*tovl-contents*  {{{1

1.  Contents  .............................................|tovl-contents|

2.  Why and what is TOVL ..................................... |tovl-why|

3.  installation / updating TOVL / How to contribute /
    contact

4.  TOVL and plugin configuration  ........................... |tovl-config|
      STRUCTURE
      MULTIPLE (PROJECT SPECIFIC) CONFIGURATION FILES
      CONFIG CACHE
      MERGING CONFIGURATIONS
      EDITING THE CONFIGURATION AND LOADING PLUGINS

5.   TOVL design notes

6.   TOVL library: a small introduction to things you should know
      TOVL TESTS
      TOVL TYPE
      TOVL OBJECT (OOP)
      TOVL LOGGING
      TOVL CHOOSE
      TOVL TRY
      TOVL RUN TASK IN BACKGROUND
      TOVL FUNCTION REFERENCES
      TOVL ...

7.   Writing TOVL plugins ................................. |tovl-plugins|

10.  TOVL FUNCTION REFERENCE (TODO)
      list of TOVL functions you should know about.

==============================================================================
2. Why and what is TOVL					*tovl-why*  {{{1
   
  TOVL tries to be
  - a configuration system for plugins
  - a high quality code base which everyone can depend uppon maximizing code sharing
  - open: everyone should be able to contribute his code and ideas

  People are reimplementing the same stuff over and over again.
  Maybe we can mimimize this using an open library.
  There is still very much which can be done.

  There is already vim.org and page http://xy, what is different?
  Noone of those script collections really solves one problem:
    How to update scripts while preseving your modified mappings ?
  How does TOVL solve this?
  TOVL separates the configuration of a "plugin" from the implementation.
  See |tovl-config|. It also tries to do the download and collection work for
  you. The downside is that you'll have a lot of files laying around which you
  won't use ever. However using |autoload-functions| this shoud be cheap and
  only waste some disk space.

  Q: Do we really need TOVL?
  R: Yes, people are already using emacs because some things do just work.
  (You can make them work in vim as well.. But you have to spend much more
  time on it..)

==============================================================================
3. installation / updating TOVL / How to contribute / contact *tovl-update* {{{1

  TOVL developement is tracked by git. git is a dezentrazied version control
  system.

  To get TOVL there are two ways:
    a) use an packed archive (.zip, .tar.gz)
        http://github.com/MarcWeber/theonevimlib (-> download button)
    b) use git
        git clone git://github.com/MarcWeber/theonevimlib.git
        git pull # this updates the repository
      you'll get the whole developement history as well.

  To install TOVL simply add this to your .vimrc
    set runtimepath+=<pathtotovl>/core
  
  You can contribute in various ways:
    a) tell me what you (dis)like
    b) send (git) patches or tell me to pull from somewhere

  My first idea was to allow everyone to push to the git repository.
  However some people (including Bram) argued that this might be a security
  risk. Anyway you have to trust me ;-)

----------------------
  contact: (add your address as well if you like)
  MarcWeber on irc.freenode.org or mail: marco-oweber@gmx.de
==============================================================================
4.  TOVL and plugin configuration                          *tovl-config* {{{1

STRUCTURE                                       *tovl-config-bar* {{{2

    The TOVL configuration is basically a huge dictionary. Vim can serialize
    this easily (string, eval). So I think this is fastest when reading.
    You should use config#Get() and config#Set() to access options.

    However the output of string(<some dict>) is hard to read. That's why
    TOVL has an implementation to serialize arbitrary vim types to human
    readable text using python like indentation. (config#ToBuffer,
    config#FromBuffer)

    However you don't have to call them yourself, see EDITING below
    Also see |config#GetByPath()| |config#GetG()|

MULTIPLE PROJECT SPECIFIC CONFIGURATION FILES  *tovl-project-secific* {{{2

    TOVL supports multiple configuration files. Use

	call config#SetG('config#filesFunc',
	  \ library#Function("return [expand('$HOME').'/.theonevimlib_config']")

    in your .vimrc to define a different list. Be careful that only you have
    access to them because someone else might add malicious code.
    (TODO check file premisions)

CONFIG CACHE					*tovl-config-cache* {{{2

    TOVL doesn't reread the configuration files from disk automatically
    if the timestamp is newer. Also the configuration file is written
    automatically if you set a value. TOVL tries to mimize the chance that
    one vim instance overrides the configuration written by another instance.
    The funtion doing all the dirty work for you is |config#ScanIfNewer|.
    You can use it in your own scripts. (I've done so to provide vimscript
    function completion).

MERGING CONFIGURATION				*tovl-config-merge* {{{2

    Imagine a plugin inserting templates. To configure it you have to tell
    it about a list of directories containing those.
    Now you work on a project and you'd like to use your own plugins and
    project specific ones. One solution is to have a
    plugin#template_sources direcotry list in you personal config and in the
    configuration file of the project directory. Now you can specify a merge
    function which concatenates both lists (see config.vim) However its very
    likely that this changes. I'd like to define the merge functions within
    the config as well (TODO)

EDITING THE CONFIGURATION AND LOADING PLUGINS      *tovl-config-edit* {{{2
    See |tovl-config-buffer.txt|

==============================================================================
5.   TOVL design notes

  If you implement a feature try to do it in a way that it can be reused.
  Example: multiple_completions.vim keeps a list for each buffer.
  You can pick a completion to be used.
  This is much better than assigning completefunc yourself because users might
  want to use different plugins at the same time. Eg in PHP it does make sense
  to have SQL and PHP and maybe even HTML or Javascript complection
  functions..

  I had in mind to never break things by using
    file#v1#Func()
  then change that to 
    file#v1#Func()
  if the interface changes

  However this will lead to many different files doing the same thing which is
  even more evil than breaking things once to make things better.
  The biggest problem about changing interfaces is that all depending code has
  to be changed as well. This can be done in one reposiotry. But this is much
  harder (I'd even say impossible) when using a distribution system such as
  scripts on www.vim.org.

  Another example is tovl/ui/open_thing_at_cursor.vim or |library#Try()|

==============================================================================
6.   TOVL library:					*tovl-library* {1

      ----------------------------------------------
      a small introduction to things you should know 
      ----------------------------------------------

TOVL TESTS						*tovl-tests* {{{2

    If you browse the library you'll see *_test.vim files. They contain
    some tests to ensure the library behaves as expected. Maybe there will
    be automatic test runners in the future.

TOVL TYPES						*tovl-type* {{{2
    I was faced by a problem (-> |tovl-function-references|). Therefor
    I had to extend the vim type system. (See |type()|)
    This is done by adding special keys to a dictionary to indicate it is not
    an arbitrary dictionary but a different type. see library#Type()

TOVL OBJECT OOP						*tovl-object* {{{2
    TOVL supports a basic OOP programming. See |tovl#obj#NewObject()|
    Basically this kind of duck typing (the way its done in Javascript).
    If something behaves like a duck it is one..
    You can also load missing features within an object at call time to
    keep startup time of vim as short as possible.
    Examples can be found in obj_test.vim.

TOVL LOGGING					        *tovl-logging* {{{2
    TOVL provides a minimal logging facility. The code has been optimized for
    speed (by keeping a list of log items which is cut only once in a while).
    Yet you can replace the code by your own if you have to.
    See |tovl#log#Log()| and the plugin |PluginLog|to view the log
    to log every log level (error=0,info=1,debug=2) use

      call tovl#log#GetLogger().SetLevel(999)

    only logging errors (level 0) is the default

TOVL CHOOSE					        *tovl-choose* {{{2
    One thing many scripts of need to do: Ask the user to pick an item from a
    list. a very simple function which can do this if you have 20 or less
    items is |tovl#ui#choice#LetUserSelectIfThereIsAChoice| which picks one
    item automatically if it's the only one.
    However I'd like to replace this by a TToC like implementation.

TOVL TRY					        *tovl-try* {{{2
    If you want test wether you should the one or the other setup then
    |library#Try| could be the function you'd like to use..

TOVL RUN TASK IN BACKGROUND		 *tovl-run-in-background* {{{2
    TODO:
    status: It can be done. You can run multiple python threads and use
    vim.command("..") however this is very likely to crash vim because vim
    is not threadsafe (yet). The only theradsafe way I know is running another
    thread either by using python threads or starting /bin/sh & .
    If you want to tell vim about therad status/ termination the only safe way
    I know about is |client-server|. I already have implemnted parts of this.
    I'd like to cleanup the code before adding it.

TOVL FUNCTION REFERENCES 		 *tovl-function-reference* {{{2
    vim already provides |function()| to create function references.
    It sucks because it assumes the function has already been loaded.
    That's bad because we'd like to make vim only load things which are
    actually used to keep vim fast.
    (Bram has sent a patch to the vim-dev mailinglist.. But I won't assume
    that you've applied that).
    
    So instead of call call(function('dir#MyFunc'),args,self) 
    use library#Call(library#Function('dir#MyFunc'),args,self)
    However both Function and Call are much more versatile because you can
    pass self by Function and you can also pass some first args of a function.
    You can also just write some small string lambdas or just use plain values:

      " pass plain values
      3 == library#Call(3)

      " make the reference contain SELF and head of args
      let F = library#Function('return [ARGS[0], ARGS[1], SELF]',
            \ { args : [2], self : dict } )
      [2,"end",dict] == library#Call(F, ["end"])

    Using Call and Function is often very convinient because they let you
    write lazy code.

    Example:

      fun! DoWithLines(lines)
        return library#Call(a:lines)[3]
      endf
      echo DoWithLines(readfile('foo'))
      " is the same as
      echo DoWithLines(library#Function('return readfile('.string('foo'))'))

      echo DoWithLines(library#Function(
        \ 'return GetFromHTTP('.string('http://www.vim.org'))'))
      " is the same as
      echo DoWithLines(library#Function(
        \ 'GetFromHTTP', {'args' : ['http://www.vim.org']})

      " This pays off if you consider this example only using the contents of
      " one template:
      InsertTemplate('template1', {
        \ 'template1' : readfile('foo'),
        \ 'template2' : readfile('foo2')
        \ })

TOVL ....

  TODO
  add  most useful stuff from the library written by Luc Hermitte
  add  most useful stuff from tlib. It already belongs to the repository.
  But it hasn't been merged yet.

==============================================================================
7.   Writing TOVL plugins ................................. *tovl-plugins*
  Have a look at the core/autoload/plugins/examples/example.vim
  file. (TODO)

  A TOVL plugin basically is an object |tovl-object| having these methods:
    Load()      : this setups the plugin
    Unload()    : this unloads the plugin
    Map         : adds a mapping [1]
    Au          : adds an au command [2]

  less important:
    LoadPlugin(): internal, this calls Load
    Log(level, msg): |tovl-logging|
    AddDefaultConfigOptions(): This adds default options to the configuration
                               Consider using self['default']['key'] = value
                               instead.

  Both [1] and [2] are remembered. The plugin tries to remove those mappings
  on unload automatically. See core/autoload/tovl/plugin_management.vim.

  LoadPlugin() automatically gets a self.cfg dict from configuration.
  Hower this conflicts with *tovl-config-merge* . So please use
  config#Get(self.pluginName.'#mypath#opt') instead if you feel that someone
  would like to merge options here for now. (Maybe the implementation should
  be enhanced..)

==============================================================================
Modelines: {{{1
 vim:tw=78:ts=8:ft=help:norl:fdm=marker
