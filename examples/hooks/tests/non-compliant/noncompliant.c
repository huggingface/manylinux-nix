/* Extension module that requires a symbol that is newer than the glibc 2.28
 * baseline of manylinux_2_28: pthread_cond_clockwait is versioned
 * GLIBC_2.30. */

#define _GNU_SOURCE
#include <Python.h>
#include <pthread.h>
#include <time.h>

static PyObject *wait_now(PyObject *self, PyObject *args) {
  pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
  pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
  struct timespec ts;
  int ret;

  clock_gettime(CLOCK_MONOTONIC, &ts);
  pthread_mutex_lock(&mutex);
  ret = pthread_cond_clockwait(&cond, &mutex, CLOCK_MONOTONIC, &ts);
  pthread_mutex_unlock(&mutex);

  return PyLong_FromLong(ret);
}

static PyMethodDef methods[] = {
    {"wait_now", wait_now, METH_NOARGS, "Wait on a condition variable."},
    {NULL, NULL, 0, NULL}};

static struct PyModuleDef module = {PyModuleDef_HEAD_INIT, "noncompliant", NULL,
                                    -1, methods};

PyMODINIT_FUNC PyInit_noncompliant(void) { return PyModule_Create(&module); }
