# Copyright 2013 David Irvine
#
# This file is part of openlava-python
#
# openlava-python is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# openlava-python is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with openlava-python.  If not, see <http://www.gnu.org/licenses/>.
"""
 
This module provides access to the openlava lsblib C API.  Lsblib enables
applications to manipulate hosts, users, queues, and jobs.

Usage
-----
Import the appropriate functions from each module::

	from openlava.lslib import ls_perror
	from openlava.lsblib import lsb_init, lsb_hostinfo, 

Initialize the openlava library by calling lsb_init, if lsb_init fails, print
the error message.
::

	if lsb_init("Hosts") < 0:
		ls_perror("lsb_init")
		sys.exit(-1)

Call the appropriate functions, in this case, get information about each host.
Where the lsblib function would normally return a struct, or array of structs,
openlava.lsblib returns an array of python objects with attributes set to the
data returned within the underlying C structures.
::

	hosts=lsb_hostinfo()
	if hosts==None:
		ls_perror("lsb_hostinfo");
		sys.exit(-1)

Function calls are kept as close as possible to the original LSB functions,
generally this means they return -1 or None on failure.  Where &num_x is
supplied as an output parameter this is generally ignored as this is
unsupported in python.  Instead use len(returned_array).
::

    for h in hosts:
	print "Host: %s has %d jobs" % (h.host, h.numJobs)


.. Warning :: Openlava reuses memory for many of its internal datastructures, this behavior is the same in the python bindings. 
	Attributes and methods are lazy, that is to say that data is only copied and returned from the underlying struct when
	accessed by the python code.  As such, be careful when creating lists of jobs from readjobinfo() calls.

Members
-------
"""

import cython
cimport openlava_base
from libc.stdlib cimport malloc, free
from libc.string cimport strcmp, memset, strcpy
from cpython.string cimport PyString_AsString
from cpython cimport bool
cimport openlava_base
from openlava.lslib import ls_perror, LSF_RLIM_NLIMITS, DEFAULT_RLIMIT

cdef extern from "lsbatch.h":
	ctypedef long long int LS_LONG_INT
	ctypedef unsigned long long LS_UNS_LONG_INT

	ctypedef long time_t
	ctypedef unsigned short u_short
	
	extern int lsberrno
	
	extern struct submit:
		int     options
		int     options2
		char    *jobName
		char    *queue
		int     numAskedHosts
		char    **askedHosts
		char    *resReq
		int     rLimits[11]
		char    *hostSpec
		int     numProcessors
		char    *dependCond
		time_t  beginTime
		time_t  termTime
		int     sigValue
		char    *inFile
		char    *outFile
		char    *errFile
		char    *command
		char    *newCommand
		time_t  chkpntPeriod
		char    *chkpntDir
		int     nxf
		xFile *xf
		char    *preExecCmd
		char    *mailUser
		int    delOptions
		int    delOptions2
		char   *projectName
		int    maxNumProcessors
		char   *loginShell
		int    userPriority
		
	extern struct hostInfoEnt:
		char   *host
		int    hStatus
		int    *busySched
		int    *busyStop
		float  cpuFactor
		int    nIdx
		float *load
		float  *loadSched
		float  *loadStop
		char   *windows
		int    userJobLimit
		int    maxJobs
		int    numJobs
		int    numRUN
		int    numSSUSP
		int    numUSUSP
		int    mig
		int    attr
		float *realLoad
		int   numRESERVE
		int   chkSig
	
	extern struct jRusage:
		int mem
		int swap
		int utime
		int stime
		int npids
		pidInfo *pidInfo
		int npgids
		int *pgid
		
	extern struct jobInfoEnt:
		LS_LONG_INT jobId
		char    *user
		int     status
		int     *reasonTb
		int     numReasons
		int     reasons
		int     subreasons
		int     jobPid
		time_t  submitTime
		time_t  reserveTime
		time_t  startTime
		time_t  predictedStartTime
		time_t  endTime
		float   cpuTime
		int     umask
		char    *cwd
		char    *subHomeDir
		char    *fromHost
		char    **exHosts
		int     numExHosts
		float   cpuFactor
		int     nIdx
		float   *loadSched
		float   *loadStop
		submit submit
		int     exitStatus
		int     execUid
		char    *execHome
		char    *execCwd
		char    *execUsername
		time_t  jRusageUpdateTime
		jRusage runRusage
		int     jType
		char    *parentGroup
		char    *jName
		int     counter[8]
		u_short port
		int     jobPriority

	extern struct jobrequeue:
		LS_LONG_INT      jobId
		int              status
		int              options

	extern struct pidInfo:
		int pid
		int ppid
		int pgid
		int jobid

	extern struct queueInfoEnt:
		char   *queue
		char   *description
		int    priority
		short  nice
		char   *userList
		char   *hostList
		int    nIdx
		float  *loadSched
		float  *loadStop
		int    userJobLimit
		float  procJobLimit
		char   *windows
		int    rLimits[11]
		char   *hostSpec
		int    qAttrib
		int    qStatus
		int    maxJobs
		int    numJobs
		int    numPEND
		int    numRUN
		int    numSSUSP
		int    numUSUSP
		int    mig
		int    schedDelay
		int    acceptIntvl
		char   *windowsD
		char   *defaultHostSpec
		int    procLimit
		char   *admins
		char   *preCmd
		char   *postCmd
		char   *prepostUsername
		char   *requeueEValues
		int    hostJobLimit
		char   *resReq
		int    numRESERVE
		int    slotHoldTime
		char   *resumeCond
		char   *stopCond
		char   *jobStarter
		char   *suspendActCmd
		char   *resumeActCmd
		char   *terminateActCmd
		int    sigMap[23]
		char   *chkpntDir
		int    chkpntPeriod
		int    defLimits[11]
		int    minProcLimit
		int    defProcLimit

	extern struct submitReply:
		char    *queue
		LS_LONG_INT  badJobId
		char    *badJobName
		int     badReqIndx
	
	extern struct userInfoEnt:
		char   *user
		float  procJobLimit
		int    maxJobs
		int    numStartJobs
		int    numJobs
		int    numPEND
		int    numRUN
		int    numSSUSP
		int    numUSUSP
		int    numRESERVE
        
	extern struct xFile:
		char subFn[256]
		char execFn[256]
		int options

	extern struct jobInfoHead:
		int   numJobs
		LS_LONG_INT *jobIds
		int   numHosts
		char  **hostNames

	extern struct loadIndexLog:
		int nIdx
		char **name
		

		
ALL_JOB        = 0x0001
DONE_JOB       = 0x0002
PEND_JOB       = 0x0004
SUSP_JOB       = 0x0008
CUR_JOB        = 0x0010
LAST_JOB       = 0x0020
RUN_JOB        = 0x0040
JOBID_ONLY     = 0x0080
HOST_NAME      = 0x0100
NO_PEND_REASONS= 0x0200
JGRP_ARRAY_INFO= 0x1000
JOBID_ONLY_ALL = 0x02000
ZOMBIE_JOB     = 0x04000		
		
EVENT_JOB_NEW = 1
EVENT_JOB_START = 2
EVENT_JOB_STATUS = 3
EVENT_JOB_SWITCH = 4
EVENT_JOB_MOVE = 5
EVENT_QUEUE_CTRL = 6
EVENT_HOST_CTRL = 7
EVENT_MBD_DIE = 8
EVENT_MBD_UNFULFILL = 9
EVENT_JOB_FINISH = 10
EVENT_LOAD_INDEX = 11
EVENT_CHKPNT = 12
EVENT_MIG = 13
EVENT_PRE_EXEC_START = 14
EVENT_MBD_START = 15
EVENT_JOB_MODIFY = 16
EVENT_JOB_SIGNAL = 17
EVENT_JOB_EXECUTE = 18
EVENT_JOB_MSG = 19
EVENT_JOB_MSG_ACK = 20
EVENT_JOB_REQUEUE = 21
EVENT_JOB_SIGACT = 22
EVENT_SBD_JOB_STATUS = 23
EVENT_JOB_START_ACCEPT = 24
EVENT_JOB_CLEAN = 25
EVENT_JOB_FORCE = 26
EVENT_LOG_SWITCH = 27
EVENT_JOB_MODIFY2 = 28
EVENT_JOB_ATTR_SET = 29
EVENT_UNUSED_30 = 30
EVENT_UNUSED_31 = 31
EVENT_UNUSED_32 = 32
H_ATTR_CHKPNTABLE = 0x1
H_ATTR_CHKPNT_COPY= 0x2
HOST_STAT_OK = 0x0
HOST_STAT_BUSY = 0x01
HOST_STAT_WIND = 0x02
HOST_STAT_DISABLED = 0x04
HOST_STAT_LOCKED = 0x08
HOST_STAT_FULL = 0x10
HOST_STAT_UNREACH = 0x20
HOST_STAT_UNAVAIL = 0x40
HOST_STAT_NO_LIM = 0x80
HOST_STAT_EXCLUSIVE = 0x100
HOST_STAT_LOCKED_MASTER = 0x200
HOST_OPEN         =1
HOST_CLOSE        =2
HOST_REBOOT       =3
HOST_SHUTDOWN     =4
JOB_STAT_NULL = 0x00
JOB_STAT_PEND = 0x01
JOB_STAT_PSUSP = 0x02
JOB_STAT_RUN = 0x04
JOB_STAT_SSUSP = 0x08
JOB_STAT_USUSP = 0x10
JOB_STAT_EXIT = 0x20
JOB_STAT_DONE = 0x40
JOB_STAT_PDONE = (0x80)
JOB_STAT_PERR = (0x100)
JOB_STAT_WAIT = (0x200)
JOB_STAT_UNKWN = 0x10000
LSB_KILL_REQUEUE=0x10
MBD_RESTART       =	0
MBD_RECONFIG      =	1
MBD_CKCONFIG      =	2
NUM_JGRP_COUNTERS=8
PEND_JOB_REASON        =0
PEND_JOB_NEW           =1
PEND_JOB_START_TIME    =2
PEND_JOB_DEPEND        =3
PEND_JOB_DEP_INVALID   =4
PEND_JOB_MIG           =5
PEND_JOB_PRE_EXEC     = 6
PEND_JOB_NO_FILE      = 7
PEND_JOB_ENV          = 8
PEND_JOB_PATHS        = 9
PEND_JOB_OPEN_FILES   = 10
PEND_JOB_EXEC_INIT    = 11
PEND_JOB_RESTART_FILE = 12
PEND_JOB_DELAY_SCHED  = 13
PEND_JOB_SWITCH       = 14
PEND_JOB_DEP_REJECT   = 15
PEND_JOB_NO_PASSWD    = 17
PEND_JOB_MODIFY       = 19
PEND_JOB_REQUEUED     = 23
PEND_SYS_UNABLE       = 35
PEND_JOB_ARRAY_JLIMIT = 38
PEND_CHKPNT_DIR       = 39
PEND_QUE_INACT             =301
PEND_QUE_WINDOW            =302
PEND_QUE_JOB_LIMIT         =303
PEND_QUE_USR_JLIMIT        =304
PEND_QUE_USR_PJLIMIT       =305
PEND_QUE_PRE_FAIL          =306
PEND_SYS_NOT_READY         =310
PEND_SBD_JOB_REQUEUE       =311
PEND_JOB_SPREAD_TASK       =312
PEND_QUE_SPREAD_TASK       =313
PEND_QUE_PJOB_LIMIT        =314
PEND_QUE_WINDOW_WILL_CLOSE= 315
PEND_QUE_PROCLIMIT   =  316
PEND_USER_JOB_LIMIT    =601
PEND_UGRP_JOB_LIMIT    =602
PEND_USER_PJOB_LIMIT   =603
PEND_UGRP_PJOB_LIMIT   =604
PEND_USER_RESUME       =605
PEND_USER_STOP         =607
PEND_NO_MAPPING        =608
PEND_RMT_PERMISSION    =609
PEND_ADMIN_STOP        =610
PEND_HOST_RES_REQ      =1001
PEND_HOST_NONEXCLUSIVE =1002
PEND_HOST_JOB_SSUSP    =1003
PEND_SBD_GETPID        =1005
PEND_SBD_LOCK          =1006
PEND_SBD_ZOMBIE        =1007
PEND_SBD_ROOT          =1008
PEND_HOST_WIN_WILL_CLOSE =1009
PEND_HOST_MISS_DEADLINE  =1010
PEND_FIRST_HOST_INELIGIBLE= 1011
PEND_HOST_DISABLED    = 1301
PEND_HOST_LOCKED      = 1302
PEND_HOST_LESS_SLOTS  = 1303
PEND_HOST_WINDOW      = 1304
PEND_HOST_JOB_LIMIT   = 1305
PEND_QUE_PROC_JLIMIT  = 1306
PEND_QUE_HOST_JLIMIT  = 1307
PEND_USER_PROC_JLIMIT = 1308
PEND_HOST_USR_JLIMIT  = 1309
PEND_HOST_QUE_MEMB    = 1310
PEND_HOST_USR_SPEC    = 1311
PEND_HOST_PART_USER   = 1312
PEND_HOST_NO_USER     = 1313
PEND_HOST_ACCPT_ONE   = 1314
PEND_LOAD_UNAVAIL     = 1315
PEND_HOST_NO_LIM      = 1316
PEND_HOST_QUE_RESREQ  = 1318
PEND_HOST_SCHED_TYPE  = 1319
PEND_JOB_NO_SPAN      = 1320
PEND_QUE_NO_SPAN      = 1321
PEND_HOST_EXCLUSIVE   =1322
PEND_UGRP_PROC_JLIMIT = 1324
PEND_BAD_HOST         = 1325
PEND_QUEUE_HOST       = 1326
PEND_HOST_LOCKED_MASTER= 1327
PEND_SBD_UNREACH     =  1601
PEND_SBD_JOB_QUOTA  =   1602
PEND_JOB_START_FAIL =   1603
PEND_JOB_START_UNKNWN=  1604
PEND_SBD_NO_MEM     =   1605
PEND_SBD_NO_PROCESS =   1606
PEND_SBD_SOCKETPAIR =   1607
PEND_SBD_JOB_ACCEPT =   1608
PEND_HOST_LOAD      =   2001
PEND_HOST_QUE_RUSAGE=  2301
PEND_HOST_JOB_RUSAGE= 2601
PEND_MAX_REASONS = 2900
QUEUE_STAT_OPEN = 0x01
QUEUE_STAT_ACTIVE = 0x02
QUEUE_STAT_RUN = 0x04
QUEUE_STAT_NOPERM = 0x08
QUEUE_STAT_DISC = 0x10
QUEUE_STAT_RUNWIN_CLOSE = 0x20
QUEUE_OPEN        =1
QUEUE_CLOSED      =2
QUEUE_ACTIVATE    =3
QUEUE_INACTIVATE  =4
REQUEUE_DONE=  0x1
REQUEUE_EXIT=  0x2
REQUEUE_RUN =  0x4
SIGKILL=9
SIGSTOP=19
SIGCONT=18
SUB_JOB_NAME = 0x01
SUB_QUEUE = 0x02
SUB_HOST = 0x04
SUB_IN_FILE = 0x08
SUB_OUT_FILE = 0x10
SUB_ERR_FILE = 0x20
SUB_EXCLUSIVE = 0x40
SUB_NOTIFY_END = 0x80
SUB_NOTIFY_BEGIN = 0x100
SUB_USER_GROUP = 0x200
SUB_CHKPNT_PERIOD = 0x400
SUB_CHKPNT_DIR = 0x800
SUB_RESTART_FORCE = 0x1000
SUB_RESTART = 0x2000
SUB_RERUNNABLE = 0x4000
SUB_WINDOW_SIG = 0x8000
SUB_HOST_SPEC = 0x10000
SUB_DEPEND_COND = 0x20000
SUB_RES_REQ = 0x40000
SUB_OTHER_FILES = 0x80000
SUB_PRE_EXEC = 0x100000
SUB_LOGIN_SHELL = 0x200000
SUB_MAIL_USER = 0x400000
SUB_MODIFY = 0x800000
SUB_MODIFY_ONCE = 0x1000000
SUB_PROJECT_NAME = 0x2000000
SUB_INTERACTIVE = 0x4000000
SUB_PTY = 0x8000000
SUB_PTY_SHELL = 0x10000000
SUB2_HOLD = 0x01
SUB2_MODIFY_CMD = 0x02
SUB2_BSUB_BLOCK = 0x04
SUB2_HOST_NT = 0x08
SUB2_HOST_UX = 0x10
SUB2_QUEUE_CHKPNT = 0x20
SUB2_QUEUE_RERUNNABLE = 0x40
SUB2_IN_FILE_SPOOL = 0x80
SUB2_JOB_CMD_SPOOL = 0x100
SUB2_JOB_PRIORITY = 0x200
SUB2_USE_DEF_PROCLIMIT = 0x400
SUB2_MODIFY_RUN_JOB = 0x800
SUB2_MODIFY_PEND_JOB = 0x1000
SUSP_USER_REASON = 0x00000000
SUSP_USER_RESUME = 0x00000001
SUSP_USER_STOP = 0x00000002
SUSP_QUEUE_REASON = 0x00000004
SUSP_QUEUE_WINDOW = 0x00000008
SUSP_HOST_LOCK = 0x00000020
SUSP_LOAD_REASON = 0x00000040
SUSP_QUE_STOP_COND = 0x00000200
SUSP_QUE_RESUME_COND = 0x00000400
SUSP_PG_IT = 0x00000800
SUSP_REASON_RESET = 0x00001000
SUSP_LOAD_UNAVAIL = 0x00002000
SUSP_ADMIN_STOP = 0x00004000
SUSP_RES_RESERVE = 0x00008000
SUSP_MBD_LOCK = 0x00010000
SUSP_RES_LIMIT = 0x00020000
SUSP_SBD_STARTUP = 0x00040000
SUSP_HOST_LOCK_MASTER = 0x00080000

LSBE_NO_ERROR = 00
LSBE_NO_JOB = 01
LSBE_NOT_STARTED = 02
LSBE_JOB_STARTED = 03
LSBE_JOB_FINISH = 04
LSBE_STOP_JOB = 05
LSBE_DEPEND_SYNTAX = 6
LSBE_EXCLUSIVE = 7
LSBE_ROOT = 8
LSBE_MIGRATION = 9
LSBE_J_UNCHKPNTABLE = 10
LSBE_NO_OUTPUT = 11
LSBE_NO_JOBID = 12
LSBE_ONLY_INTERACTIVE = 13
LSBE_NO_INTERACTIVE = 14
LSBE_NO_USER = 15
LSBE_BAD_USER = 16
LSBE_PERMISSION = 17
LSBE_BAD_QUEUE = 18
LSBE_QUEUE_NAME = 19
LSBE_QUEUE_CLOSED = 20
LSBE_QUEUE_WINDOW = 21
LSBE_QUEUE_USE = 22
LSBE_BAD_HOST = 23
LSBE_PROC_NUM = 24
LSBE_RESERVE1 = 25
LSBE_RESERVE2 = 26
LSBE_NO_GROUP = 27
LSBE_BAD_GROUP = 28
LSBE_QUEUE_HOST = 29
LSBE_UJOB_LIMIT = 30
LSBE_NO_HOST = 31
LSBE_BAD_CHKLOG = 32
LSBE_PJOB_LIMIT = 33
LSBE_NOLSF_HOST = 34
LSBE_BAD_ARG = 35
LSBE_BAD_TIME = 36
LSBE_START_TIME = 37
LSBE_BAD_LIMIT = 38
LSBE_OVER_LIMIT = 39
LSBE_BAD_CMD = 40
LSBE_BAD_SIGNAL = 41
LSBE_BAD_JOB = 42
LSBE_QJOB_LIMIT = 43
LSBE_UNKNOWN_EVENT = 44
LSBE_EVENT_FORMAT = 45
LSBE_EOF = 46
LSBE_MBATCHD = 47
LSBE_SBATCHD = 48
LSBE_LSBLIB = 49
LSBE_LSLIB = 50
LSBE_SYS_CALL = 51
LSBE_NO_MEM = 52
LSBE_SERVICE = 53
LSBE_NO_ENV = 54
LSBE_CHKPNT_CALL = 55
LSBE_NO_FORK = 56
LSBE_PROTOCOL = 57
LSBE_XDR = 58
LSBE_PORT = 59
LSBE_TIME_OUT = 60
LSBE_CONN_TIMEOUT = 61
LSBE_CONN_REFUSED = 62
LSBE_CONN_EXIST = 63
LSBE_CONN_NONEXIST = 64
LSBE_SBD_UNREACH = 65
LSBE_OP_RETRY = 66
LSBE_USER_JLIMIT = 67
LSBE_JOB_MODIFY = 68
LSBE_JOB_MODIFY_ONCE = 69
LSBE_J_UNREPETITIVE = 70
LSBE_BAD_CLUSTER = 71
LSBE_JOB_MODIFY_USED = 72
LSBE_HJOB_LIMIT = 73
LSBE_NO_JOBMSG = 74
LSBE_BAD_RESREQ = 75
LSBE_NO_ENOUGH_HOST = 76
LSBE_CONF_FATAL = 77
LSBE_CONF_WARNING = 78
LSBE_NO_RESOURCE = 79
LSBE_BAD_RESOURCE = 80
LSBE_INTERACTIVE_RERUN = 81
LSBE_PTY_INFILE = 82
LSBE_BAD_SUBMISSION_HOST = 83
LSBE_LOCK_JOB = 84
LSBE_UGROUP_MEMBER = 85
LSBE_OVER_RUSAGE = 86
LSBE_BAD_HOST_SPEC = 87
LSBE_BAD_UGROUP = 88
LSBE_ESUB_ABORT = 89
LSBE_EXCEPT_ACTION = 90
LSBE_JOB_DEP = 91
LSBE_JGRP_NULL = 92
LSBE_JGRP_BAD = 93
LSBE_JOB_ARRAY = 94
LSBE_JOB_SUSP = 95
LSBE_JOB_FORW = 96
LSBE_BAD_IDX = 97
LSBE_BIG_IDX = 98
LSBE_ARRAY_NULL = 99
LSBE_JOB_EXIST = 100
LSBE_JOB_ELEMENT = 101
LSBE_BAD_JOBID = 102
LSBE_MOD_JOB_NAME = 103
LSBE_PREMATURE = 104
LSBE_BAD_PROJECT_GROUP = 105
LSBE_NO_HOST_GROUP = 106
LSBE_NO_USER_GROUP = 107
LSBE_INDEX_FORMAT = 108
LSBE_SP_SRC_NOT_SEEN = 109
LSBE_SP_FAILED_HOSTS_LIM = 110
LSBE_SP_COPY_FAILED = 111
LSBE_SP_FORK_FAILED = 112
LSBE_SP_CHILD_DIES = 113
LSBE_SP_CHILD_FAILED = 114
LSBE_SP_FIND_HOST_FAILED = 115
LSBE_SP_SPOOLDIR_FAILED = 116
LSBE_SP_DELETE_FAILED = 117
LSBE_BAD_USER_PRIORITY = 118
LSBE_NO_JOB_PRIORITY = 119
LSBE_JOB_REQUEUED = 120
LSBE_MULTI_FIRST_HOST = 121
LSBE_HG_FIRST_HOST = 122
LSBE_HP_FIRST_HOST = 123
LSBE_OTHERS_FIRST_HOST = 124
LSBE_PROC_LESS = 125
LSBE_MOD_MIX_OPTS = 126
LSBE_MOD_CPULIMIT = 127
LSBE_MOD_MEMLIMIT = 128
LSBE_MOD_ERRFILE = 129
LSBE_LOCKED_MASTER = 130
LSBE_DEP_ARRAY_SIZE = 131
LSBE_NUM_ERR = 131


def create_job_id(job_id, array_index):
	"""openlava.lsblib.create_job_id(job_id, array_index)
	
Takes a job_id, and array_index, and returns the Openlava JOB id specific to that job/array_id combination.

:param int job_id: The job id
:param int array_index: The array index of the job
:return: full job id
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.create_job_id(1000, 1)
	4294968296
	
"""
	id=array_index
	id=id << 32
	id=id | job_id
	return id

def get_array_index(LS_LONG_INT job_id):
	"""openlava.lsblib.get_array_index(job_id)
	
Takes an Openlava job id, and returns the array index

:param int job_id: full job id as returned from openlava
:return: The array index of the job
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.get_array_index(4294968296)
	1
	
"""
	if job_id == -1:
		array_index=0
	else:
		array_index=( job_id >> 32 ) & 0x0FFFF
	return array_index

def get_job_id(job_id):
	"""openlava.lsblib.get_job_id(job_id)

Takes an Openlava job id, and returns the Job ID
::

	>>> from openlava import lsblib
	>>> lsblib.get_job_id(4294968296)
	1000
	
"""
	if job_id==-1:
		id=-1
	else:
		id=job_id & 0x0FFFFFFFF
	return id

def get_lsberrno():
	"""openlava.lsblib.get_lsberrno()

Returns the lsberrno

:return: LSB Errno
:rtype: int

::

	LSBE_NO_ERROR = 00
	LSBE_NO_JOB = 01
	LSBE_NOT_STARTED = 02
	LSBE_JOB_STARTED = 03
	LSBE_JOB_FINISH = 04
	LSBE_STOP_JOB = 05
	LSBE_DEPEND_SYNTAX = 6
	LSBE_EXCLUSIVE = 7
	LSBE_ROOT = 8
	LSBE_MIGRATION = 9
	LSBE_J_UNCHKPNTABLE = 10
	LSBE_NO_OUTPUT = 11
	LSBE_NO_JOBID = 12
	LSBE_ONLY_INTERACTIVE = 13
	LSBE_NO_INTERACTIVE = 14
	LSBE_NO_USER = 15
	LSBE_BAD_USER = 16
	LSBE_PERMISSION = 17
	LSBE_BAD_QUEUE = 18
	LSBE_QUEUE_NAME = 19
	LSBE_QUEUE_CLOSED = 20
	LSBE_QUEUE_WINDOW = 21
	LSBE_QUEUE_USE = 22
	LSBE_BAD_HOST = 23
	LSBE_PROC_NUM = 24
	LSBE_RESERVE1 = 25
	LSBE_RESERVE2 = 26
	LSBE_NO_GROUP = 27
	LSBE_BAD_GROUP = 28
	LSBE_QUEUE_HOST = 29
	LSBE_UJOB_LIMIT = 30
	LSBE_NO_HOST = 31
	LSBE_BAD_CHKLOG = 32
	LSBE_PJOB_LIMIT = 33
	LSBE_NOLSF_HOST = 34
	LSBE_BAD_ARG = 35
	LSBE_BAD_TIME = 36
	LSBE_START_TIME = 37
	LSBE_BAD_LIMIT = 38
	LSBE_OVER_LIMIT = 39
	LSBE_BAD_CMD = 40
	LSBE_BAD_SIGNAL = 41
	LSBE_BAD_JOB = 42
	LSBE_QJOB_LIMIT = 43
	LSBE_UNKNOWN_EVENT = 44
	LSBE_EVENT_FORMAT = 45
	LSBE_EOF = 46
	LSBE_MBATCHD = 47
	LSBE_SBATCHD = 48
	LSBE_LSBLIB = 49
	LSBE_LSLIB = 50
	LSBE_SYS_CALL = 51
	LSBE_NO_MEM = 52
	LSBE_SERVICE = 53
	LSBE_NO_ENV = 54
	LSBE_CHKPNT_CALL = 55
	LSBE_NO_FORK = 56
	LSBE_PROTOCOL = 57
	LSBE_XDR = 58
	LSBE_PORT = 59
	LSBE_TIME_OUT = 60
	LSBE_CONN_TIMEOUT = 61
	LSBE_CONN_REFUSED = 62
	LSBE_CONN_EXIST = 63
	LSBE_CONN_NONEXIST = 64
	LSBE_SBD_UNREACH = 65
	LSBE_OP_RETRY = 66
	LSBE_USER_JLIMIT = 67
	LSBE_JOB_MODIFY = 68
	LSBE_JOB_MODIFY_ONCE = 69
	LSBE_J_UNREPETITIVE = 70
	LSBE_BAD_CLUSTER = 71
	LSBE_JOB_MODIFY_USED = 72
	LSBE_HJOB_LIMIT = 73
	LSBE_NO_JOBMSG = 74
	LSBE_BAD_RESREQ = 75
	LSBE_NO_ENOUGH_HOST = 76
	LSBE_CONF_FATAL = 77
	LSBE_CONF_WARNING = 78
	LSBE_NO_RESOURCE = 79
	LSBE_BAD_RESOURCE = 80
	LSBE_INTERACTIVE_RERUN = 81
	LSBE_PTY_INFILE = 82
	LSBE_BAD_SUBMISSION_HOST = 83
	LSBE_LOCK_JOB = 84
	LSBE_UGROUP_MEMBER = 85
	LSBE_OVER_RUSAGE = 86
	LSBE_BAD_HOST_SPEC = 87
	LSBE_BAD_UGROUP = 88
	LSBE_ESUB_ABORT = 89
	LSBE_EXCEPT_ACTION = 90
	LSBE_JOB_DEP = 91
	LSBE_JGRP_NULL = 92
	LSBE_JGRP_BAD = 93
	LSBE_JOB_ARRAY = 94
	LSBE_JOB_SUSP = 95
	LSBE_JOB_FORW = 96
	LSBE_BAD_IDX = 97
	LSBE_BIG_IDX = 98
	LSBE_ARRAY_NULL = 99
	LSBE_JOB_EXIST = 100
	LSBE_JOB_ELEMENT = 101
	LSBE_BAD_JOBID = 102
	LSBE_MOD_JOB_NAME = 103
	LSBE_PREMATURE = 104
	LSBE_BAD_PROJECT_GROUP = 105
	LSBE_NO_HOST_GROUP = 106
	LSBE_NO_USER_GROUP = 107
	LSBE_INDEX_FORMAT = 108
	LSBE_SP_SRC_NOT_SEEN = 109
	LSBE_SP_FAILED_HOSTS_LIM = 110
	LSBE_SP_COPY_FAILED = 111
	LSBE_SP_FORK_FAILED = 112
	LSBE_SP_CHILD_DIES = 113
	LSBE_SP_CHILD_FAILED = 114
	LSBE_SP_FIND_HOST_FAILED = 115
	LSBE_SP_SPOOLDIR_FAILED = 116
	LSBE_SP_DELETE_FAILED = 117
	LSBE_BAD_USER_PRIORITY = 118
	LSBE_NO_JOB_PRIORITY = 119
	LSBE_JOB_REQUEUED = 120
	LSBE_MULTI_FIRST_HOST = 121
	LSBE_HG_FIRST_HOST = 122
	LSBE_HP_FIRST_HOST = 123
	LSBE_OTHERS_FIRST_HOST = 124
	LSBE_PROC_LESS = 125
	LSBE_MOD_MIX_OPTS = 126
	LSBE_MOD_CPULIMIT = 127
	LSBE_MOD_MEMLIMIT = 128
	LSBE_MOD_ERRFILE = 129
	LSBE_LOCKED_MASTER = 130
	LSBE_DEP_ARRAY_SIZE = 131
	LSBE_NUM_ERR = 131
	
	>>> from openlava import lsblib, lslib
	>>> lsblib.lsb_init("foo")
	0
	>>> lsblib.lsb_hostcontrol("foo", 2)
	-1
	>>> lsblib.get_lsberrno()
	17
	>>> lsblib.lsb_perror("foo")
	foo: User permission denied
	>>> lsblib.lsb_sysmsg()
	u'User permission denied'
	>>> 

"""
	return lsberrno

cdef char ** to_cstring_array(list_str):
	cdef char **ret = <char **>malloc(len(list_str) * sizeof(char *))
	if ret==NULL:
		raise MemoryError()
	for i in xrange(len(list_str)):
		ret[i] = PyString_AsString(list_str[i])
	return ret

cdef int * to_int_array(list_int):
	cdef int *ret=<int *>malloc(sizeof(int) * len(list_int))
	if ret==NULL:
		raise MemoryError()
	for i in range(len(list_int)):
		ret[i]=list_int[i]
	return ret

cdef LS_LONG_INT * to_ls_long_int_array(list_int):
	cdef LS_LONG_INT *ret=<LS_LONG_INT *>malloc(sizeof(LS_LONG_INT) * len(list_int))
	if ret==NULL:
		raise MemoryError()
	for i in range(len(list_int)):
		ret[i]=list_int[i]
	return ret


def lsb_closejobinfo():
	"""
Closes the connection to the MBD that was opened with lsb_openjobinfo()
::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("closejobinfo")
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...     job=lsblib.lsb_readjobinfo()
	...     print job.jobId
	... 
	4562
	>>> lsblib.lsb_closejobinfo()

"""
	openlava_base.lsb_closejobinfo()

def lsb_deletejob(job_id, submit_time, options=0):
	"""openlava.lsblib.lsb_deletejob(job_id, submit_time, [options=0])
	
Removes a job from the schedluing system.  If the job is running it is killed.

:param str job_id: Job ID of the job to kill
:param int submit_time: epoch time of the job submission
:param int options: If options == lsblib.LSB_KILL_REQUEUE job will be requeued with the same job id, else it is completely removed
:return: 0 on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("deletejob")
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...     job=lsblib.lsb_readjobinfo()
	...     print "Killing job: %d" % job.jobId
	...     lsblib.lsb_deletejob(job.jobId, job.submitTime)
	... 
	Killing job: 4562
	-1
	>>> lsblib.lsb_closejobinfo()

"""
	return openlava_base.lsb_deletejob(job_id, submit_time, options)

def lsb_hostcontrol(host, opCode):
	"""openlava.lsblib.lsb_hostcontrol(host, opCode)

Opens or closes a host, shutsdown or restarts SBD.

:param str host: Hostname of host
:param int opCode: Opcode, one of either HOST_CLOSE, HOST_OPEN, HOST_REBOOT, HOST_SHUTDOWN.
:return: 0 on success, -1 on failure.
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("hostcontrol")
	>>> lsblib.lsb_hostcontrol("localhost", lsblib.HOST_OPEN)
	-1

"""

	opCode=int(opCode)
	host=str(host)
	return openlava_base.lsb_hostcontrol(host, opCode)

def lsb_hostinfo(hosts=[], numHosts=0):
	"""openlava.lsblib.lsb_hostinfo(hosts=[], numHosts=0)

Returns information about Openlava hosts.

:param array hosts: Array of hostnames
:param int numHosts: Number of hosts, if set to 1 and hosts is empty, returns information on the local host
:return: Array of HostInfoEnt objects
:rtype: array

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("host test")
	0
	>>> for host in lsblib.lsb_hostinfo():
	...     print host.host
	... 
	master
	comp00
	comp01
	comp02
	comp03
	comp04
	>>> for host in lsblib.lsb_hostinfo(numHosts=1):
	...     print host.host
	... 
	master
	
"""
	assert(isinstance(hosts,list))
	cdef int num_hosts

	cdef char ** host_list
	if numHosts==1 and len(hosts)==0:
		host_list=NULL
		num_hosts=numHosts
	else:
		host_list=to_cstring_array(hosts)
		num_hosts=len(hosts)

	cdef hostInfoEnt *host_info
	cdef hostInfoEnt *h

	host_info=openlava_base.lsb_hostinfo(host_list, &num_hosts)
	if host_info==NULL:
		return None

	hl=[]
	for i in range (num_hosts):
		h=&host_info[i]
		host=HostInfoEnt()
		host._load_struct(h)
		hl.append(host)
	return hl

def lsb_init(appName):
	"""openlava.lsblib.lsb_init(appName)	

Initialize the lsb library

:param str appName: A name for the calling application
:return: status - 0 on success, -1 on failure.
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("testing")
	0

"""
	return openlava_base.lsb_init(appName)

def lsb_modify(jobSubReq, jobSubReply, jobId):
	"""openlava.lsblib.lsb_modify(jobSubReq, jobSubReply, jobId)	
Modifies an existing job

:param Submit jobSubReq: Submit request
:param SubmitReply jobSubReply: Submit reply
:param int jobId: Job ID
:return: Job ID, -1 on failure.
:rtype: int
"""
	assert(isinstance(jobSubReq, Submit))
	assert(isinstance(jobSubReply,SubmitReply))
	assert(isinstance(jobId,int))
	job_id=jobSubReq._modify(jobSubReply, jobId)
	return job_id

def lsb_openjobinfo(job_id=0, job_name="", user="all", queue="", host="", options=ALL_JOB):
	"""openlava.lsblib.lsb_openjobinfo(job_id=0, job_name="", user="all", queue="", host="", options=0)
Get information about jobs that match the specified criteria.

.. note:: Only one parameter may be used at any given time.   

:param int job_id: Return jobs with this job id.
:param str job_name: Return jobs with this name
:param str user: Return jobs owned by this user
:param str host: Return jobs on this host
:param int options: Return jobs that match the following options, where option is a bitwise or of the following paramters: ALL_JOB - All jobs; CUR_JOB - All unfinished jobs; DONE_JOB - Jobs that have finished or exited; PEND_JOB - Jobs that are pending; SUSP_JOB - Jobs that are suspended; LAST_JOB - The last submitted job
:return: Number of jobs that match, -1 on error
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("testing")
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...     job=lsblib.lsb_readjobinfo()
	...     print job.jobId
	... 
	4562
	>>> lsblib.lsb_closejobinfo()
	

"""
	cdef int numJob
	numJobs=openlava_base.lsb_openjobinfo(job_id,job_name,user,queue,host,options)
	return numJobs



def lsb_pendreason (numReasons, rsTb, jInfoH, ld):
	"""openlava.lsblib.lsb_pendreason(numReasons, rsTb, jInfoH, ld)
Get the reason a job is pending

:param int numReasons: The length of the reasons array
:param list rsTb: An array of integer reasons
:param JobInfoHead jInfoH: Job info header, may be None
:param LoadIndexLog ld: LoadIndexLog, use to set specific names of load indexes.
:return: Description of job pending reasons
:rtype: str
    
::
	
	>>> from openlava import lsblib
	>>> lsblib.lsb_init("Job Test")
	0
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...         job=lsblib.lsb_readjobinfo()
	...         ld=lsblib.LoadIndexLog()
	...         if job.status & lsblib.JOB_STAT_PEND != 0:
	...                 print "Job %d: %s" % (job.jobId, lsblib.lsb_pendreason(job.numReasons, job.reasonTb, None, ld))
	... 


"""
	cdef int * reasonsTb 
	reasonsTb=to_int_array(rsTb)
	cdef jobInfoHead jInfo
	
	if jInfoH != None:
		jInfo.jobIds=NULL
		jInfo.hostNames=NULL
		jInfo.numJobs=jInfoH.numJobs
		jInfo.jobIds=to_ls_long_int_array(jInfoH.hobIds)
		jInfo.numHosts=jInfoH.numHosts
		jInfo.hostNames=to_cstring_array(jInfoH.hostNames)
	cdef loadIndexLog loadIndex
	loadIndex.nIdx=ld.nIdx
	loadIndex.name=to_cstring_array(ld.name)
	reasons=openlava_base.lsb_pendreason(numReasons, reasonsTb, &jInfo, &loadIndex)
	if jInfoH != None:
		free(jInfo.jobIds)
		free(jInfo.hostNames)
	return u"%s" % reasons

def lsb_peekjob(jobId):
	"""
Get the name of the file where job output is being spooled.

:param int jobId: The ID of the job
:return: Path to the file, or None if not available
:rtype: str

::

	>>> from openlava import lsblib
	>>> 
	>>> 
	>>> from openlava import lsblib
	>>> lsblib.lsb_init("peek")
	0
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...     job=lsblib.lsb_readjobinfo()
	...     print "Job: %s: %s" % (job.jobId, lsblib.lsb_peekjob(job.jobId))
	... 
	Job: 4562: /home/brian/.lsbatch/1390404552.4562
	>>> 

"""
	jobId=int(jobId)
	cdef char * fname
	fname=openlava_base.lsb_peekjob(jobId)
	if fname==NULL:
		return None
	else:
		return fname
	

def lsb_perror(message):
	"""openlava.lsblib.lsb_perror(message)

Prints the lsblib error message associated with the lsberrno prefixed by message.

:param str message: User defined error message
:return: None
:rtype: None

::

	>>> from openlava import lsblib, lslib
	>>> lsblib.lsb_init("foo")
	0
	>>> lsblib.lsb_hostcontrol("foo", 2)
	-1
	>>> lsblib.get_lsberrno()
	17
	>>> lsblib.lsb_perror("foo")
	foo: User permission denied
	>>> lsblib.lsb_sysmsg()
	u'User permission denied'
	>>> 

"""
	cdef char * m
	message=str(message)
	m=message
	openlava_base.lsb_perror(m)
	
	
def lsb_queuecontrol(queue, opCode):
	"""openlava.lsblib.lsb_queuecontrol(queue, opCode)
Opens, closes, activates or inactivates a queue.
	
:param str queue: Name of queue to control
:param int opCode: OpCode to use, one of either: lslblib.QUEUE_OPEN - open the queue; lsblib.QUEUE_CLOSED - close the queue; QUEUE_ACTIVATE - activate the queue; QUEUE_INACTIVATE - inactivate the queue
:return: 0 on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("queuecontrol")
	0
	>>> lsblib.lsb_queuecontrol("normal", lsblib.QUEUE_CLOSED)
	-1


"""
	queue=str(queue)
	opCode=int(opCode)
	return openlava_base.lsb_queuecontrol(queue, opCode)

def lsb_queueinfo(queues=[], numqueues=0, hostname="", username="", options=0):
	"""openlava.lsblib.lsb_queueinfo(queues=[], numqueues=0, hostname="", username="", options=0)
Get information on specified queues.

:param array queues: list of queue names to get information on
:param int numqueues: number of queues to get information on, if queues is empty, and numqueues=1, gets information on the default queue
:param str hostname: get queues that can execute on hostname
:param str username: get queues that username can submit to
:param int options: Options
:return: array of QueueInfoEnt objects, None on error.
:rtype: array

.. note:: Unlike the C api, numqueues is not set to to the number of queues returned as this is not supported in Python. Instead use len on the returned array.

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("testing")
	0
	>>> for q in lsblib.lsb_queueinfo():
	...     print q.queue
	... 
	normal
	>>> for q in lsblib.lsb_queueinfo(numqueues=1):
	...     print q.queue
	... 
	normal
	>>> for q in lsblib.lsb_queueinfo(hostname='master'):
	...     print q.queue
	... 
	normal
	>>> 

"""
	queue_list=[]
	cdef queueInfoEnt * qs

	cdef char **queueNames
	cdef int numQueues
	if len(queues)>0:
		queueNames=to_cstring_array(queues)
		numQueues=len(queues)
	else:
		queueNames=NULL
		numqueues=int(numqueues)
		numQueues=numqueues

	cdef char * hostName
	hostName=NULL
	hostname=str(hostname)
	if len(hostname)>0:
		hostName=hostname

	cdef char * userName
	userName=NULL
	username=str(username)
	if len(username)>0:
		userName=username

	cdef int opts
	options=int(options)
	opts=options

	qs=openlava_base.lsb_queueinfo(queueNames, &numQueues, hostName, userName, opts)
	if qs==NULL:
		return None
	
	for i in range(numQueues):
		q=QueueInfoEnt()
		q._load_struct(&qs[i])
		queue_list.append(q)
	return queue_list

def lsb_readjobinfo():
	"""openlava.lsblib.lsb_readjobinfo()
Get the next job in the list from the MBD.

.. note:: The more parameter is not supported as passing integers as in/out parameters is not supported by Python.  

:param int options: Return jobs that match the following options, where option is a bitwise or of the following paramters: ALL_JOB - All jobs; CUR_JOB - All unfinished jobs; DONE_JOB - Jobs that have finished or exited; PEND_JOB - Jobs that are pending; SUSP_JOB - Jobs that are suspended; LAST_JOB - The last submitted job
:return: JobInfoEnt object or None on error
:rtype: JobInfoEnt

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("testing")
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...     job=lsblib.lsb_readjobinfo()
	...     print job.jobId
	... 
	4562
	>>> lsblib.lsb_closejobinfo()
	

"""
	cdef jobInfoEnt * j
	cdef int * more
	more=NULL
	j=openlava_base.lsb_readjobinfo(more)
	a=JobInfoEnt()
	a._load_struct(j)
	return a

def lsb_reconfig(opCode):
	"""openlava.lsblib.lsb_reconfig(opCode)

Reloads configuration information for the batch system.

:param int opCode: Operation to perform: lsblib.MBD_RESTART - restart the MBD; lsblib.MBD_RECONFIG - Reconfigure the MBD; lsblib.MBD_CKCONFIG - Check the configuration
:return: 0 on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("mbd control")
	0
	>>> lsblib.lsb_reconfig(lsblib.MBD_CKCONFIG)
	-1
	>>>

"""
	opCode=int(opCode)
	return openlava_base.lsb_reconfig(opCode)

def lsb_requeuejob(rq):
	"""openlava.lsblib.lsb_requeuejob(rq)

Requeues a job.

:param JobRequeue rq: JobRequeue object
:return: 0 on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("requeue")
	0
	>>> rq=lsblib.JobRequeue()
	>>> rq.jobId=lsblib.create_job_id(4563,0)
	>>> rq.status=lsblib.JOB_STAT_PEND
	>>> rq.options=lsblib.REQUEUE_RUN
	>>> lsblib.lsb_requeuejob(rq)
	0

"""
	assert(isinstance(rq,JobRequeue))
	return rq._requeue()

def lsb_signaljob (jobId, sigValue):
	"""openlava.lsblib.lsb_signaljob(jobId, sigValue)

Sends the specified signal to the job.

:param int jobId: Id of the job
:param int sigValue: signal to send
:return: 0 on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib	
	>>> lsblib.lsb_init("signaljob")
	0
	>>> lsblib.lsb_signaljob(4563, lsblib.SIGSTOP)
	0
	>>> lsblib.lsb_signaljob(4563, lsblib.SIGCONT)
	0

"""
	return openlava_base.lsb_signaljob(jobId, sigValue)

def lsb_submit(jobSubReq, jobSubReply):
	"""openlava.lsblib.lsb_submit(jobSubReq, jobSubReply)

Submits a new job into the scheduling environment.

:param Submit jobSubReq: Submit object containing job submission information
:param SubmitReply jobSubReply: SubmitReply object
:return: job_id on success, -1 on failure
:rtype: int

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("submit")
	0
	>>> sr=lsblib.Submit()
	>>> sr.command="hostname"
	>>> sr.numProcessors=1
	>>> sr.maxNumProcessors=1
	>>> srep=lsblib.SubmitReply()
	>>> lsblib.lsb_submit(sr, srep)
	Job <4564> is submitted to default queue <normal>.
	4564
	>>> 

"""
	assert(isinstance(jobSubReq, Submit))
	assert(isinstance(jobSubReply,SubmitReply))
	job_id=jobSubReq._submit(jobSubReply)
	return job_id

def lsb_suspreason (reasons, subreasons, ld):
	"""openlava.lsblib.lsb_suspreason(reasons, subreasons, ld)

Get reasons why a job is suspended

:param int reasons: reasons from jobinfoent
:param int subreasons: subreasons from jobinfoent
:param LoadIndexLog ld: LoadIndexLog with index names
:returns: Description of why job is pending
:rtype: str

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("suspreasons")
	0
	>>> lsblib.lsb_signaljob(4563, lsblib.SIGSTOP)
	0
	>>> for i in range(lsblib.lsb_openjobinfo()):
	...         job=lsblib.lsb_readjobinfo()
	...         ld=lsblib.LoadIndexLog()
	...         if job.status & lsblib.JOB_STAT_USUSP !=0 or job.status & lsblib.JOB_STAT_SSUSP != 0:
	...                 print "Job %d: %s" % (job.jobId, lsblib.lsb_suspreason(job.reasons, job.subreasons, ld))
	... 
	
	Job 4563:  The job was suspended by user;

"""

	cdef loadIndexLog loadIndex
	loadIndex.nIdx=ld.nIdx
	loadIndex.name=to_cstring_array(ld.name)
	reasons=openlava_base.lsb_suspreason(reasons, subreasons, &loadIndex)
	return u"%s" % reasons

def lsb_sysmsg():
	"""openlava.lsblib.lsb_sysmsg()

Get the lsblib error message associated with lsberrno

:return: LSBLIB error message
:rtype: str

::

	>>> from openlava import lsblib, lslib
	>>> lsblib.lsb_init("foo")
	0
	>>> lsblib.lsb_hostcontrol("foo", 2)
	-1
	>>> lsblib.get_lsberrno()
	17
	>>> lsblib.lsb_perror("foo")
	foo: User permission denied
	>>> lsblib.lsb_sysmsg()
	u'User permission denied'
	>>> 

"""
	cdef char * msg
	msg=openlava_base.lsb_sysmsg()
	if msg==NULL:
		return u""
	else:
		return u"%s" % msg

def lsb_userinfo(user_list=[], numusers=0):
	"""openlava.lsblib.lsb_userinfo(user_list=[])

Get information on specified users

.. note:: Unlike in the C API, numusers is not set to the size of the returned array, as this is not supported in Python.

:param array user_list: List of usernames to get information on
:param int numusers: ignored unless user_list is empty, if numusers is set to one, then returns information about the current user.
:rtype: array
:return: List of UserInfoEnt objects

::

	>>> from openlava import lsblib
	>>> lsblib.lsb_init("userinfo")
	0
	>>> for user in lsblib.lsb_userinfo():
	...     print user.user
	... 
	default
	root
	irvined
	>>> for user in lsblib.lsb_userinfo(user_list=[], numusers=1):
	...     print user.user
	... 
	irvined
	>>> 
	
"""
	assert(isinstance(user_list,list))
	numusers=int(numusers)
	cdef int num_users
	cdef char ** users
	users=NULL
	
	if len(user_list)>0:
		num_users=len(user_list)
		users=to_cstring_array(user_list)
	else:
		num_users=numusers
		
	cdef userInfoEnt *user_info
	cdef userInfoEnt *u

	user_info=openlava_base.lsb_userinfo(users,&num_users)
	if user_info == NULL:
		return None
	usrs=[]
	for i in range(num_users):
		u=&user_info[i]
		user=UserInfoEnt()
		user._load_struct(u)
		usrs.append(user)
	return usrs

cdef class HostInfoEnt:
	cdef hostInfoEnt * _data

	cdef _load_struct(self, hostInfoEnt * data ):
		self._data=data

	property host:
		def __get__(self):
			return u'%s' % self._data.host

	property hStatus:
		def __get__(self):
			return self._data.hStatus

	property busySched:
		def __get__(self):
			return [self._data.busySched[i] for i in range(self.nIdx)]

	property busyStop:
		def __get__(self):
			return [self._data.busyStop[i] for i in range(self.nIdx)]

	property cpuFactor:
		def __get__(self):
			return self._data.cpuFactor

	property nIdx:
		def __get__(self):
			return self._data.nIdx

	property load:
		def __get__(self):
			return [self._data.load[i] for i in range(self.nIdx)]

	property loadSched:
		def __get__(self):
			return [self._data.loadSched[i] for i in range(self.nIdx)]

	property loadStop:
		def __get__(self):
			return [self._data.loadStop[i] for i in range(self.nIdx)]

	property windows:
		def __get__(self):
			return u'%s' % self._data.windows

	property userJobLimit:
		def __get__(self):
			return self._data.userJobLimit

	property maxJobs:
		def __get__(self):
			return self._data.maxJobs

	property numJobs:
		def __get__(self):
			return self._data.numJobs

	property numRUN:
		def __get__(self):
			return self._data.numRUN

	property numSSUSP:
		def __get__(self):
			return self._data.numSSUSP

	property numUSUSP:
		def __get__(self):
			return self._data.numUSUSP

	property mig:
		def __get__(self):
			return self._data.mig

	property attr:
		def __get__(self):
			return self._data.attr

	property realLoad:
		def __get__(self):
			return [self._data.realLoad[i] for i in range(self.nIdx)]

	property numRESERVE:
		def __get__(self):
			return self._data.numRESERVE

	property chkSig:
		def __get__(self):
			return self._data.chkSig


cdef class JobInfoEnt:
	cdef jobInfoEnt * _data

	cdef _load_struct(self, jobInfoEnt * data ):
		self._data=data

	property jobId:
		def __get__(self):
			return self._data.jobId

	property user:
		def __get__(self):
			return u'%s' % self._data.user

	property status:
		def __get__(self):
			return self._data.status

	property reasonTb:
		def __get__(self):
			return [self._data.reasonTb[i] for i in range(self.numReasons)]

	property numReasons:
		def __get__(self):
			return self._data.numReasons

	property reasons:
		def __get__(self):
			return self._data.reasons

	property subreasons:
		def __get__(self):
			return self._data.subreasons

	property jobPid:
		def __get__(self):
			return self._data.jobPid

	property submitTime:
		def __get__(self):
			return self._data.submitTime

	property reserveTime:
		def __get__(self):
			return self._data.reserveTime

	property startTime:
		def __get__(self):
			return self._data.startTime

	property predictedStartTime:
		def __get__(self):
			return self._data.predictedStartTime

	property endTime:
		def __get__(self):
			return self._data.endTime

	property cpuTime:
		def __get__(self):
			return self._data.cpuTime

	property umask:
		def __get__(self):
			return self._data.umask

	property cwd:
		def __get__(self):
			return u'%s' % self._data.cwd

	property subHomeDir:
		def __get__(self):
			return u'%s' % self._data.subHomeDir

	property fromHost:
		def __get__(self):
			return u'%s' % self._data.fromHost

	property exHosts:
		def __get__(self):
			return [ u'%s' % self._data.exHosts[i] for i in range(self.numExHosts)]

	property numExHosts:
		def __get__(self):
			return self._data.numExHosts

	property cpuFactor:
		def __get__(self):
			return self._data.cpuFactor

	property nIdx:
		def __get__(self):
			return self._data.nIdx

	property loadSched:
		def __get__(self):
			return [self._data.loadSched[i] for i in range(self.nIdx)]

	property loadStop:
		def __get__(self):
			return [self._data.loadStop[i] for i in range(self.nIdx)]

	property submit:
		def __get__(self):
			s=Submit()
			s._load_struct(&self._data.submit)
			return s

	property exitStatus:
		def __get__(self):
			return self._data.exitStatus

	property execUid:
		def __get__(self):
			return self._data.execUid

	property execHome:
		def __get__(self):
			return u'%s' % self._data.execHome

	property execCwd:
		def __get__(self):
			return u'%s' % self._data.execCwd

	property execUsername:
		def __get__(self):
			return u'%s' % self._data.execUsername

	property jRusageUpdateTime:
		def __get__(self):
			return self._data.jRusageUpdateTime

	property runRusage:
		def __get__(self):
			r=JRusage()
			r._load_struct(&self._data.runRusage)
			return r

	property jType:
		def __get__(self):
			return self._data.jType

	property parentGroup:
		def __get__(self):
			return u'%s' % self._data.parentGroup

	property jName:
		def __get__(self):
			return u'%s' % self._data.jName

	property counter:
		def __get__(self):
			return [self._data.counter[i] for i in range(7)]

	property port:
		def __get__(self):
			return self._data.port

	property jobPriority:
		def __get__(self):
			return self._data.jobPriority


cdef class JobRequeue:
	cdef jobrequeue _data

	property jobId:
		def __get__(self):
			return self._data.jobId
		def __set__(self,v):
			v=int(v)
			self._data.jobId=v

	property status:
		def __get__(self):
			return self._data.status
		def __set__(self,v):
			v=int(v)
			self._data.status=v

	property options:
		def __get__(self):
			return self._data.options
		def __set__(self,v):
			v=int(v)
			self._data.options=v

	def _requeue(self):
		status=self.status
		if status!=JOB_STAT_PEND and status!=JOB_STAT_PSUSP:
			raise ValueError("Invalid Status") 
		options=self.options
		if options != REQUEUE_DONE and options != REQUEUE_EXIT and options != REQUEUE_RUN:
			raise ValueError("Invalid Option")
		return openlava_base.lsb_requeuejob(&self._data)


cdef class JRusage:
	cdef jRusage * _data

	cdef _load_struct(self, jRusage * data ):
		self._data=data

	property mem:
		def __get__(self):
			return self._data.mem

	property swap:
		def __get__(self):
			return self._data.swap

	property utime:
		def __get__(self):
			return self._data.utime

	property stime:
		def __get__(self):
			return self._data.stime

	property npids:
		def __get__(self):
			return self._data.npids

	property pidInfo:
		def __get__(self):
			pids=[]
			for i in range(self.npids):
				p=PidInfo()
				p._load_struct(self._data.pidInfo)
				pids.append(p)
			return pids

	property npgids:
		def __get__(self):
			return self._data.npgids

	property pgid:
		def __get__(self):
			return [ self._data.pgid[i] for i in range(self.npgids)]


cdef class PidInfo:
	cdef pidInfo * _data

	cdef _load_struct(self, pidInfo * data ):
		self._data=data

	property pid:
		def __get__(self):
			return self._data.pid

	property ppid:
		def __get__(self):
			return self._data.ppid

	property pgid:
		def __get__(self):
			return self._data.pgid

	property jobid:
		def __get__(self):
			return self._data.jobid


cdef class QueueInfoEnt:
	cdef queueInfoEnt * _data

	cdef _load_struct(self, queueInfoEnt * data ):
		self._data=data

	property queue:
		def __get__(self):
			return u'%s' % self._data.queue

	property description:
		def __get__(self):
			return u'%s' % self._data.description

	property priority:
		def __get__(self):
			return self._data.priority

	property nice:
		def __get__(self):
			return self._data.nice

	property userList:
		def __get__(self):
			return [u'%s' % i for i in self._data.userList.split()]

	property hostList:
		def __get__(self):
			return [u'%s' % i for i in self._data.hostList.split()]

	property nIdx:
		def __get__(self):
			return int(self._data.nIdx)

	property loadSched:
		def __get__(self):
			return [float(self._data.loadSched[i]) for i in range(self.nIdx)]

	property loadStop:
		def __get__(self):
			return [float(self._data.loadStop[i]) for i in range(self.nIdx)]

	property userJobLimit:
		def __get__(self):
			return self._data.userJobLimit

	property procJobLimit:
		def __get__(self):
			return float(self._data.procJobLimit)

	property windows:
		def __get__(self):
			return u'%s' % self._data.windows

	property rLimits:
		def __get__(self):
			return [self._data.rLimits[i] for i in range(11)]

	property hostSpec:
		def __get__(self):
			return u'%s' % self._data.hostSpec

	property qAttrib:
		def __get__(self):
			return self._data.qAttrib

	property qStatus:
		def __get__(self):
			return self._data.qStatus

	property maxJobs:
		def __get__(self):
			return self._data.maxJobs

	property numJobs:
		def __get__(self):
			return self._data.numJobs

	property numPEND:
		def __get__(self):
			return self._data.numPEND

	property numRUN:
		def __get__(self):
			return self._data.numRUN

	property numSSUSP:
		def __get__(self):
			return self._data.numSSUSP

	property numUSUSP:
		def __get__(self):
			return self._data.numUSUSP

	property mig:
		def __get__(self):
			return self._data.mig

	property schedDelay:
		def __get__(self):
			return self._data.schedDelay

	property acceptIntvl:
		def __get__(self):
			return self._data.acceptIntvl

	property windowsD:
		def __get__(self):
			return u'%s' % self._data.windowsD

	property defaultHostSpec:
		def __get__(self):
			return u'%s' % self._data.defaultHostSpec

	property procLimit:
		def __get__(self):
			return self._data.procLimit

	property admins:
		def __get__(self):
			return u'%s' % self._data.admins

	property preCmd:
		def __get__(self):
			return u'%s' % self._data.preCmd

	property postCmd:
		def __get__(self):
			return u'%s' % self._data.postCmd

	property prepostUsername:
		def __get__(self):
			return u'%s' % self._data.prepostUsername

	property requeueEValues:
		def __get__(self):
			return u'%s' % self._data.requeueEValues

	property hostJobLimit:
		def __get__(self):
			return self._data.hostJobLimit

	property resReq:
		def __get__(self):
			return u'%s' % self._data.resReq

	property numRESERVE:
		def __get__(self):
			return self._data.numRESERVE

	property slotHoldTime:
		def __get__(self):
			return self._data.slotHoldTime

	property resumeCond:
		def __get__(self):
			return u'%s' % self._data.resumeCond

	property stopCond:
		def __get__(self):
			return u'%s' % self._data.stopCond

	property jobStarter:
		def __get__(self):
			return u'%s' % self._data.jobStarter

	property suspendActCmd:
		def __get__(self):
			return u'%s' % self._data.suspendActCmd

	property resumeActCmd:
		def __get__(self):
			return u'%s' % self._data.resumeActCmd

	property terminateActCmd:
		def __get__(self):
			return u'%s' % self._data.terminateActCmd

	property sigMap:
		def __get__(self):
			return [self._data.sigMap[i] for i in range(22)]

	property chkpntDir:
		def __get__(self):
			return u'%s' % self._data.chkpntDir

	property chkpntPeriod:
		def __get__(self):
			return self._data.chkpntPeriod

	property defLimits:
		def __get__(self):
			return [self._data.rLimits[i] for i in range(11)]

	property minProcLimit:
		def __get__(self):
			return self._data.minProcLimit

	property defProcLimit:
		def __get__(self):
			return self._data.defProcLimit

cdef class Submit:
	cdef submit * _data
	cdef bool _tainted

	def __cinit__(self):
		self._tainted=False

	cdef _load_struct(self, submit * data ):
		self._tainted=True
		self._data=data

	def _modify(self, reply, jobId):
		cdef submitReply subRep
		jobId=openlava_base.lsb_modify(self._data, &subRep, jobId)

	def _submit(self, reply):
		cdef submitReply subRep
		jobId=openlava_base.lsb_submit(self._data, &subRep)
		reply.queue=subRep.queue
		if jobId<0:
			reply.badJobId=subRep.badJobId
			reply.badJobName=subRep.badJobName
			reply.badReqIndx=subRep.badReqIndx
		return jobId

	def _check_set(self):
		if self._tainted:
			raise ValueError
		if self._data==NULL:
			self._data = <submit *>malloc(sizeof(submit))
			self._data.options=0
			self._data.options2=0
			self._data.jobName=NULL
			self._data.queue=NULL
			self._data.numAskedHosts=0
			self._data.askedHosts=NULL
			self._data.resReq=NULL
			for i in range(LSF_RLIM_NLIMITS):
				self._data.rLimits[i]=DEFAULT_RLIMIT
			self._data.hostSpec = NULL
			self._data.numProcessors=0
			self._data.dependCond=NULL
			self._data.beginTime=0
			self._data.termTime=0
			self._data.sigValue=0
			self._data.inFile=NULL
			self._data.outFile=NULL
			self._data.errFile=NULL
			self._data.command=NULL
			self._data.newCommand=NULL
			self._data.chkpntPeriod=0
			self._data.chkpntDir=NULL
			self._data.nxf=0
			self._data.xf=NULL
			self._data.preExecCmd=NULL
			self._data.mailUser=NULL
			self._data.delOptions=0
			self._data.delOptions2=0
			self._data.projectName = NULL
			self._data.maxNumProcessors=0
			self._data.loginShell=NULL
			self._data.userPriority=-1

	property options:
		def __get__(self):
			return self._data.options
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.options=v

	property options2:
		def __get__(self):
			return self._data.options2
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.options2=v

	property jobName:
		def __get__(self):
			return u'%s' % self._data.jobName
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.jobName=v

	property queue:
		def __get__(self):
			return u'%s' % self._data.queue
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.queue=v

	property numAskedHosts:
		def __get__(self):
			return self._data.numAskedHosts
		# Only set when askedHosts is set.

	property askedHosts:
		def __get__(self):
			return [u'%s' % self._data.askedHosts[i] for i in range(self.numAskedHosts)]
		def __set__(self,hosts):
			self._data.askedHosts=to_cstring_array(hosts)
			self._data.numAskedHosts=len(hosts)
			

	property resReq:
		def __get__(self):
			return u'%s' % self._data.resReq
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.resReq=v

	property rLimits:
		def __get__(self):
			return [self._data.rLimits[i] for i in range(11)]
		def __set__(self,v):
			assert(isinstance(v,list))
			assert(len(v),11)
			for i in range(11):
				assert(isinstance(v[i],int))
				self._data.rLimits[i]=v[i]


	property hostSpec:
		def __get__(self):
			return u'%s' % self._data.hostSpec
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.hostSpec=v

	property numProcessors:
		def __get__(self):
			return self._data.numProcessors
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.numProcessors=v

	property dependCond:
		def __get__(self):
			return u'%s' % self._data.dependCond
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.dependCond=v

	property beginTime:
		def __get__(self):
			return self._data.beginTime
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.beginTime=v

	property termTime:
		def __get__(self):
			return self._data.termTime
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.termTime=v

	property sigValue:
		def __get__(self):
			return self._data.sigValue
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.sigValue=v

	property inFile:
		def __get__(self):
			return u'%s' % self._data.inFile
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.inFile=v

	property outFile:
		def __get__(self):
			return u'%s' % self._data.outFile
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.outFile=v

	property errFile:
		def __get__(self):
			return u'%s' % self._data.errFile
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.errFile=v

	property command:
		def __get__(self):
			return u'%s' % self._data.command
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.command=v

	property newCommand:
		def __get__(self):
			return u'%s' % self._data.newCommand
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.newCommand=v

	property chkpntPeriod:
		def __get__(self):
			return self._data.chkpntPeriod
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.chkpntPeriod=v

	property chkpntDir:
		def __get__(self):
			return u'%s' % self._data.chkpntDir
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.chkpntDir=v

	property nxf:
		def __get__(self):
			return self._data.nxf
		# Only ever set when XF is written to.

	property xf:
		def __get__(self):
			xfs=[]
			for i in range(self.nxf):
				x=XFile()
				x._load_struct(&self._data.xf[i])
				xfs.append(x)
			return xfs
		def __set__(self,xfs):
			assert(isinstance(xfs,list))
			for xf in xfs:
				assert(isinstance(xf,XFile))
			free(self._data.xf)
			if len(xfs)>0:
				self._data.xf = <xFile *>malloc(len(xf)*cython.sizeof(xFile))
			if self._data.xf is NULL:
				raise MemoryError()
			for i in range(len(xfs)):
				for c in len(xfs[i].subFn):
					self._data.xf[i].subFn[c]=xfs[i].subFn[c]
				for c in len(xfs[i].subFn):
					self._data.xf[i].execFn[c]=xfs[i].execFn[c]
				self._data.xf[i].options=xfs[i].options
			self._data.nxf=len(xfs)
		


	property preExecCmd:
		def __get__(self):
			return u'%s' % self._data.preExecCmd
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.preExecCmd=v

	property mailUser:
		def __get__(self):
			return u'%s' % self._data.mailUser
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.mailUser=v

	property delOptions:
		def __get__(self):
			return self._data.delOptions
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.delOptions=v

	property delOptions2:
		def __get__(self):
			return self._data.delOptions2
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.delOptions2=v

	property projectName:
		def __get__(self):
			return u'%s' % self._data.projectName
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.projectName=v

	property maxNumProcessors:
		def __get__(self):
			return self._data.maxNumProcessors
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.maxNumProcessors=v

	property loginShell:
		def __get__(self):
			return u'%s' % self._data.loginShell
		def __set__(self,v):
			self._check_set()
			v=str(v)
			self._data.loginShell=v

	property userPriority:
		def __get__(self):
			return self._data.userPriority
		def __set__(self,v):
			self._check_set()
			v=int(v)
			self._data.userPriority=v


class SubmitReply:
	def __init__(self):
		self.queue=""
		self.badJobId=0
		self.badJobName=""
		self.badReqIndx=0


cdef class UserInfoEnt:
	cdef userInfoEnt * _data
	cdef _load_struct(self, userInfoEnt * data ):
		self._data=data

	property user:
		def __get__(self):
			return u'%s' % self._data.user

	property procJobLimit:
		def __get__(self):
			return self._data.procJobLimit

	property maxJobs:
		def __get__(self):
			return self._data.maxJobs

	property numStartJobs:
		def __get__(self):
			return self._data.numStartJobs

	property numJobs:
		def __get__(self):
			return self._data.numJobs

	property numPEND:
		def __get__(self):
			return self._data.numPEND

	property numRUN:
		def __get__(self):
			return self._data.numRUN

	property numSSUSP:
		def __get__(self):
			return self._data.numSSUSP

	property numUSUSP:
		def __get__(self):
			return self._data.numUSUSP

	property numRESERVE:
		def __get__(self):
			return self._data.numRESERVE


cdef class XFile:
	cdef xFile * _data
	cdef bool _tainted
	
	def __cinit__(self):
		self._tainted=False
	
	cdef _load_struct(self, xFile * data ):
		self._tainted=True
		self._data=data
	
	def _check_set(self):
		if self._tainted:
			raise ValueError
		if self._data==NULL:
			self._data = <xFile *>malloc(sizeof(xFile))
			self._data.options=0
	property subFn:
		def __get__(self):
			return self._data.subFn
		def __set__(self,v):
			cdef char * b
			self._check_set()
			v=str(v)
			if len(v)>256:
				raise ValueError("String to big")
			b=v
			strcpy(self._data.subFn, b)
		
	property execFn:
		def __get__(self):
			return self._data.execFn
		def __set__(self,v):
			cdef char * b
			self._check_set()
			v=str(v)
			if len(v)>256:
				raise ValueError("String to big")
			b=v
			strcpy(self._data.execFn, b)

	property options:
		def __get__(self):
			return self._data.options
		def __set__(self,v):
			v=int(v)
			self._data.options=v
		
cdef class JobInfoHead:
	cdef jobInfoHead * _data
	cdef _load_struct(self, jobInfoHead * data ):
		self._data=data
		
	property numJobs:
		def __get__(self):
			return int(self._data.numJobs)
	property jobIds:
		def __get__(self):
			[int(self._data.jobIds[i]) for i in range(self.numJobs)]
	property numHosts:
		def __get__(self):
			return int(self._data.numHosts)
	property hostNames:
		def __get__(self):
			[int(self._data.hostNames[i]) for i in range(self.numHosts)]
		
class LoadIndexLog:
	def __init__(self):
		self.name=[]
	
	@property
	def nIdx(self):
		return len(self.name)
	