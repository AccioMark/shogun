/*
 * This software is distributed under BSD 3-clause license (see LICENSE file).
 *
 * Authors: Viktor Gal, Sergey Lisitsyn
 */

#ifdef SWIGPYTHON

%include "protocols_helper.i"

/* Numeric operators for CustomKernel */
%define NUMERIC_CUSTOMKERNEL(class_name, type_name, format_str, operator_name, operator)

PyObject* class_name ## _inplace ## operator_name ## (PyObject *self, PyObject *o2)
{
	PyObject* resultobj=NULL;

	CCustomKernel* arg1=NULL; // self in c++ repr
	int res1=0; // result for self's casting
	void* argp1=NULL; // pointer to self

	PyObject* kernel_narray=NULL;
	SGMatrix< type_name > kernel_matrix;

	res1 = SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1),
					"in method '" "inplace operator_name" "', argument " "1"" of type '" "CCustomKernel *""'");
	}

	arg1=reinterpret_cast< CCustomKernel* >(argp1);

	kernel_matrix=arg1->get_float32_kernel_matrix();
	kernel_narray=PySequence_GetSlice(self, 0, kernel_matrix.num_rows);
	PyNumber_InPlace ## operator ## (kernel_narray, o2);

	resultobj=self;
	Py_INCREF(resultobj);
	return resultobj;

fail:
	return NULL;
}

%enddef // NUMERIC_CUSTOMKERNEL

/* Python protocols for CustomKernel */
%define PROTOCOLS_CUSTOMKERNEL(class_name, type_name, format_str, typecode)

%wrapper
%{

/* used by PyObject_GetBuffer */
static int class_name ## _getbuffer(PyObject *self, Py_buffer *view, int flags)
{
	CCustomKernel* arg1=(CCustomKernel *) 0; // self in c++ repr
	void* argp1=0; // pointer to self
	int res1=0; // result for self's casting

	int num_rows=0, num_cols=0;
	Py_ssize_t* shape=NULL;
	Py_ssize_t* strides=NULL;
	SGMatrix< type_name > kernel_matrix;

	buffer_matrix_ ## type_name ## _info* info=NULL;

	static char* format=(char *) format_str; // http://docs.python.org/dev/library/struct.html#module-struct

	res1 = SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1),
					"in method '" "getbuffer" "', argument " "1"" of type '" "CCustomKernel *""'");
	}

	if ((flags & PyBUF_C_CONTIGUOUS)==PyBUF_C_CONTIGUOUS)
	{
		PyErr_SetString(PyExc_ValueError, "class_name is not C-contiguous");
		goto fail;
	}

	if ((flags & PyBUF_STRIDES)!=PyBUF_STRIDES &&
		(flags & PyBUF_ND)==PyBUF_ND)
	{
		PyErr_SetString(PyExc_ValueError, "class_name is not C-contiguous");
		goto fail;
	}

	arg1=reinterpret_cast< CCustomKernel* >(argp1);

	info=(buffer_matrix_ ## type_name ## _info*) malloc(sizeof(buffer_matrix_ ## type_name ## _info));
	new (&info->buf) SGMatrix< type_name >();

	kernel_matrix=arg1->get_float32_kernel_matrix();

	info->buf=kernel_matrix;
	num_rows=kernel_matrix.num_rows;
	num_cols=kernel_matrix.num_cols;

	view->buf=kernel_matrix.matrix;

	shape=new Py_ssize_t[2];
	shape[0]=num_rows;
	shape[1]=num_cols;

	strides=new Py_ssize_t[2];
	strides[0]=sizeof( type_name );
	strides[1]=sizeof( type_name ) * num_rows;

	info->shape=shape;
	info->strides=strides;
	info->internal=NULL;

	view->ndim=2;

	view->format=(char*) format_str;
	view->itemsize=sizeof( type_name );

	view->len=(shape[0]*shape[1])*view->itemsize;
	view->shape=shape;
	view->strides=strides;

	view->readonly=0;
	view->suboffsets=NULL;
	view->internal=(void*) info;

	view->obj=(PyObject*) self;
	Py_INCREF(self);

	return 0;

fail:
	view->obj=NULL;
	return -1;
}

/* used by PyBuffer_Release */
static void class_name ## _releasebuffer(PyObject *self, Py_buffer *view)
{
	buffer_matrix_ ## type_name ## _info* temp=NULL;
	if (view->obj!=NULL && view->internal!=NULL)
	{
		temp=(buffer_matrix_ ## type_name ## _info*) view->internal;
		if (temp->shape!=NULL)
			delete[] temp->shape;

		if (temp->strides!=NULL)
			delete[] temp->strides;

		temp->buf=SGMatrix< type_name >();
		free(temp);
	}
}

/* used by PySequence_GetItem */
static PyObject* class_name ## _getitem(PyObject *self, Py_ssize_t idx)
{
	CCustomKernel* arg1=0; // self in c++ repr
	void* argp1=0; // pointer to self
	int res1=0; // result for self's casting

	char* data=0; // internal data of self
	int num_rows=0;
	int num_cols=0;

	SGMatrix< type_name > kernel_matrix;

	Py_ssize_t* shape;
	Py_ssize_t* strides;

	PyArrayObject* ret;
	PyArray_Descr* descr=PyArray_DescrFromType(typecode);

	res1 = SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1),
					"in method '" " class_name _getitem" "', argument " "1"" of type '" "CCustomKernel *""'");
	}

	arg1=reinterpret_cast< CCustomKernel* >(argp1);

	kernel_matrix=arg1->get_float32_kernel_matrix();
	num_rows=kernel_matrix.num_rows;
	num_cols=kernel_matrix.num_cols;

	data=(char*) kernel_matrix.matrix;

	idx=get_idx_in_bounds(idx, num_rows);
	if (idx < 0)
	{
		goto fail;
	}

	data+=idx * sizeof( type_name );

	shape=new Py_ssize_t[2];
	shape[0]=1;
	shape[1]=num_cols;

	strides=new Py_ssize_t[2];
	strides[0]=sizeof( type_name );
	strides[1]=sizeof( type_name ) * num_rows;

	ret=(PyArrayObject *) PyArray_NewFromDescr(&PyArray_Type, descr,
					1, shape+1,
					strides+1, data,
					NPY_ARRAY_FARRAY | NPY_ARRAY_WRITEABLE,
					(PyObject *) self);
	if (ret==NULL)
		goto fail;

	Py_INCREF(self);
	return (PyObject*)ret;

fail:
	return NULL;
}

/* used by PySequence_SetItem */
static int class_name ## _setitem(PyObject *self, Py_ssize_t idx, PyObject *v)
{
	PyArrayObject* tmp=NULL;
	int ret=0;

	if (v==NULL)
	{
		// TODO error message
		goto fail;
	}

	tmp=(PyArrayObject *) class_name ## _getitem(self, idx);
	if(tmp==NULL)
	{
		goto fail;
	}
	ret=PyArray_CopyObject(tmp, v);
	Py_DECREF(tmp);
	return ret;

fail:
	return -1;
}


/* used by PySequence_GetSlice */
static PyObject* class_name ## _getslice(PyObject *self, Py_ssize_t ilow, Py_ssize_t ihigh)
{
	CCustomKernel* arg1=0; // self in c++ repr
	void* argp1=0; // pointer to self
	int res1=0 ; // result for self's casting

	int num_rows=0, num_cols=0;
	char* data=0; // internal data of self

	SGMatrix< type_name > kernel_matrix;

	Py_ssize_t* shape;
	Py_ssize_t* strides;

	PyArrayObject* ret;
	PyArray_Descr* descr=PyArray_DescrFromType(typecode);

	res1=SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1),
					"in method '" " class_name _slice" "', argument " "1"" of type '" "CCustomKernel *""'");
	}

	arg1=reinterpret_cast< CCustomKernel* >(argp1);

	kernel_matrix=arg1->get_float32_kernel_matrix();
	num_rows=kernel_matrix.num_rows;
	num_cols=kernel_matrix.num_cols;

	data=(char*) kernel_matrix.matrix;

	get_slice_in_bounds(&ilow, &ihigh, num_rows);
	if (ilow < ihigh)
	{
		data+=ilow * sizeof( type_name );
	}

	shape=new Py_ssize_t[2];
	shape[0]=ihigh - ilow;
	shape[1]=num_cols;

	strides=new Py_ssize_t[2];
	strides[0]=sizeof( type_name );
	strides[1]=sizeof( type_name ) * num_rows;

	ret=(PyArrayObject *) PyArray_NewFromDescr(&PyArray_Type, descr,
					2, shape,
					strides, data,
					NPY_ARRAY_FARRAY | NPY_ARRAY_WRITEABLE,
					(PyObject *) self);
	if (ret==NULL)
		goto fail;

	Py_INCREF(self);
	return (PyObject *) ret;

fail:
	return NULL;
}

/* used by PySequence_SetSlice */
static int class_name ## _setslice(PyObject *self, Py_ssize_t ilow, Py_ssize_t ihigh, PyObject* v)
{
	PyArrayObject* tmp=NULL;
	int ret=0;

	if (v==NULL)
	{
		// TODO error message
		goto fail;
	}

	tmp=(PyArrayObject *) class_name ## _getslice(self, ilow, ihigh);
	if(tmp==NULL)
	{
		goto fail;
	}
	ret = PyArray_CopyObject(tmp, v);
	Py_DECREF(tmp);
	return ret;

fail:
	return -1;
}

/* used for numpy's style slicing */
static PyObject* class_name ## _getsubscript_helper(PyObject *self, PyObject *key, bool get_scalar=true)
{
	// key is tuple, like (PySlice or PyLong, PySlice or PyLong)
	// or only PySlice/PyLong

	CCustomKernel* arg1=0; // self in c++ repr
	void* argp1=0; // pointer to self
	int res1=0 ; // result for self's casting

	int num_rows=0;
	int num_cols=0;
	int ndims=2;
	char* data = 0; // internal data of self

	Py_ssize_t* shape;
	Py_ssize_t* strides;

	SGMatrix< type_name > kernel_matrix;

	PyObject* ret;
	PyArray_Descr* descr=PyArray_DescrFromType(typecode);

	int num_items=0; // size of tuple
	int type_item1=0; // results for tuple parsing
	int type_item2=0;

	Py_ssize_t row_high=0;
	Py_ssize_t row_low=0;
	Py_ssize_t col_high=0;
	Py_ssize_t col_low=0;

	Py_ssize_t rows_step=0;
	Py_ssize_t cols_step=0;
	Py_ssize_t rows_slicelength=0;
	Py_ssize_t cols_slicelength=0;

	PyObject* tmp; // temporary object for tuple's item

	res1 = SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1),
					"in method '" " class_name _subscript" "', argument " "1"" of type '" "CCustomKernel *""'");
	}

	arg1=reinterpret_cast< CCustomKernel* >(argp1);

	kernel_matrix=arg1->get_float32_kernel_matrix();
	num_rows=kernel_matrix.num_rows;
	num_cols=kernel_matrix.num_cols;

	data=(char*) kernel_matrix.matrix;

	row_high=num_rows;
	col_high=num_cols;

	if(PyTuple_Check(key))
	{
		num_items=PyTuple_GET_SIZE(key);
		if (num_items==2)
		{
			// get slice for feat's dim
			tmp=PyTuple_GET_ITEM(key, 0); // first element of tuple
			type_item1=parse_tuple_item(tmp, num_rows,
								&row_low, &row_high,
								&rows_step, &rows_slicelength);
			if (type_item1==0)
			{
				goto fail;
			}

			// get slice for vector's dim
			tmp=PyTuple_GET_ITEM(key, 1); // second element of tuple
			type_item2=parse_tuple_item(tmp, num_cols,
								&col_low, &col_high,
								&cols_step, &cols_slicelength);
			if (type_item2==0)
			{
				goto fail;
			}
		}
		else
		{
			SWIG_exception_fail(SWIG_ArgError(res1), "same size is needed");
			goto fail;
		}

		shape = new Py_ssize_t[2];
		shape[0]=row_high-row_low;
		shape[1]=col_high-col_low;

		strides=new Py_ssize_t[2];
		strides[0]=sizeof( type_name );
		strides[1]=sizeof( type_name ) * num_rows;

		data+=row_low*strides[0]+col_low*strides[1];

		// not slice item should give vector or scalar
		if (type_item1==1)
		{
			// transpose
			++shape;
			++strides;
			--ndims;
		}
		if (type_item2==1)
		{
			--ndims;
		}

		if (ndims==0 && get_scalar)
		{
			ret=(PyObject *) PyArray_Scalar(data, descr, (PyObject *) self);
		}
		else
		{
			ret=(PyObject *) PyArray_NewFromDescr(&PyArray_Type, descr,
					ndims, shape,
					strides, data,
					NPY_ARRAY_FARRAY | NPY_ARRAY_WRITEABLE,
					(PyObject *) self);
		}

		if (ret==NULL)
		{
			// TODO error message
			goto fail;
		}

		Py_INCREF(self);
		return ret;
	}
	else if (PySlice_Check(key) || PyInt_Check(key) || PyArray_IsScalar(key, Integer) ||
		PyLong_Check(key) || (PyIndex_Check(key) && !PySequence_Check(key)))
	{
		int item_type;
		item_type=parse_tuple_item(key, num_rows,
							&row_low, &row_high,
							&rows_step, &rows_slicelength);

		switch (item_type)
		{
		case 1:
			return class_name ## _getitem(self, row_low);
			break;
		case 2:
			return class_name ## _getslice(self, row_low, row_high);
			break;
		default:
			goto fail;
		}
	}

fail:
	return NULL;
}

static PyObject* class_name ## _getsubscript(PyObject *self, PyObject *key)
{
	return class_name ##  _getsubscript_helper(self, key, true);
}

/* used for numpy's style slicing */
static int class_name ## _setsubscript(PyObject *self, PyObject *key, PyObject* v)
{
	PyArrayObject* tmp=NULL;
	int ret=0;

	if (v==NULL)
	{
		// TODO error message
		goto fail;
	}

	tmp = (PyArrayObject *) class_name ## _getsubscript_helper(self, key, false);
	if(tmp == NULL)
	{
		goto fail;
	}
	ret = PyArray_CopyObject(tmp, v);
	Py_DECREF(tmp);
	return ret;

fail:
	return -1;
}

static PyObject* class_name ## _cleanup_custom(PyObject *self, PyObject *args)
{
	PyObject* resultobj=NULL;
	CCustomKernel* arg1=NULL;
	void* argp1=NULL;
	int res1=0;

	res1=SWIG_ConvertPtr(self, &argp1, SWIG_TypeQuery("shogun::CCustomKernel"), 0 |  0 );
	if (!SWIG_IsOK(res1))
	{
		SWIG_exception_fail(SWIG_ArgError(res1), "in method '"
				"cleanup" "', argument " "1"" of type '" "shogun::CCustomKernel *""'");
	}

	arg1=reinterpret_cast< CCustomKernel * >(argp1);
	{
		try
		{
			Py_buffer* view=NULL;
			buffer_matrix_ ## type_name ## _info* temp=NULL;
			if (extend_ ## class_name ## _info.count(arg1)>0)
			{
				view=extend_ ## class_name ## _info[arg1];
				temp=(buffer_matrix_ ## type_name ## _info*) view->internal;
				view->internal=temp->internal;

				PyBuffer_Release(view);
				extend_ ## class_name ## _info.erase(arg1);

				free(temp);
				delete view;
			}

			arg1->cleanup();
		}

		catch (std::bad_alloc)
		{
			SWIG_exception(SWIG_MemoryError, const_cast<char*>("Out of memory error.\n"));

			SWIG_fail;

		}
		catch (shogun::ShogunException e)
		{
			SWIG_exception(SWIG_SystemError, const_cast<char*>(e.what()));

			SWIG_fail;

		}
	}
	resultobj=SWIG_Py_Void();
	return resultobj;
fail:
	return NULL;
}

NUMERIC_DENSEFEATURES(class_name, type_name, format_str, add, Add)
NUMERIC_DENSEFEATURES(class_name, type_name, format_str, sub, Subtract)
NUMERIC_DENSEFEATURES(class_name, type_name, format_str, mul, Multiply)

static long class_name ## _flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_HAVE_NEWBUFFER | Py_TPFLAGS_BASETYPE;
%}

%init
%{
// overload flags slot in DenseFatures proxy class
SwigPyBuiltin__shogun__CCustomKernel_type.ht_type.tp_flags = class_name ## _flags;

// overload free_feature_matrix in DenseFeatures
set_method(SwigPyBuiltin__shogun__CCustomKernel_methods, "cleanup_custom", (PyCFunction) class_name ## _cleanup_custom);

%}

%header
%{

#include <map>
static std::map< CCustomKernel*, Py_buffer*> extend_ ## class_name ## _info;

%}

%feature("python:bf_getbuffer") CCustomKernel #class_name "_getbuffer"
%feature("python:bf_releasebuffer") CCustomKernel #class_name "_releasebuffer"

%feature("python:nb_inplace_add") CCustomKernel #class_name "_inplaceadd"
%feature("python:nb_inplace_subtract") CCustomKernel #class_name "_inplacesub"
%feature("python:nb_inplace_multiply") CCustomKernel #class_name "_inplacemul"

%feature("python:sq_item") CCustomKernel #class_name "_getitem"
%feature("python:sq_ass_item") CCustomKernel #class_name "_setitem"
%feature("python:sq_slice") CCustomKernel #class_name "_getslice"
%feature("python:sq_ass_slice") CCustomKernel #class_name "_setslice"

%feature("python:mp_subscript") CCustomKernel #class_name "_getsubscript"
%feature("python:mp_ass_subscript") CCustomKernel #class_name "_setsubscript"

%enddef /* PROTOCOLS_CUSTOMKERNEL */

%define EXTEND_CUSTOMKERNEL(class_name, type_name, typecode)

%extend shogun::CCustomKernel
{

int frombuffer(PyObject* exporter, bool copy)
{
	Py_buffer* view=NULL;
	buffer_matrix_ ## type_name ## _info* info=NULL;
	SGMatrix< type_name > new_kernel_matrix;

	int res1=0;
	int res2=0;

	res1=PyObject_CheckBuffer(exporter);
	if (!res1)
	{
		PyErr_SetString(PyExc_BufferError, "this object does not support the python buffer protocol");
		return -1;
	}

	view=new Py_buffer;
	res2=PyObject_GetBuffer(exporter, view, PyBUF_F_CONTIGUOUS | PyBUF_ND | PyBUF_STRIDES | 0);
	if (res2!=0 || view->buf==NULL)
	{
		PyErr_SetString(PyExc_BufferError, "bad buffer");
		return -1;
	}

	// checking that buffer is right
	if (view->ndim!=2)
	{
		PyErr_SetString(PyExc_BufferError, "wrong dimension");
		return -1;
	}

	if (view->itemsize!=sizeof(type_name))
	{
		PyErr_SetString(PyExc_BufferError, "wrong type");
		return -1;
	}

	if (view->shape==NULL)
	{
		PyErr_SetString(PyExc_BufferError, "wrong shape");
		return -1;
	}

	new_kernel_matrix=SGMatrix< type_name >((type_name*) view->buf, view->shape[0], view->shape[1], true);

	if (copy)
	{
		$self->set_full_kernel_matrix_from_full(new_kernel_matrix.clone());
	}
	else
	{
		$self->set_full_kernel_matrix_from_full(new_kernel_matrix);
	}

	info=(buffer_matrix_ ## type_name ## _info*) malloc(sizeof(buffer_matrix_ ## type_name ## _info));
	new (&info->buf) SGMatrix< type_name >();

	info->buf=new_kernel_matrix;
	info->shape=view->shape;
	info->strides=view->strides;
	info->internal=view->internal;

	view->internal=info;

	extend_ ## class_name ## _info[$self]=view;

	return 0;
}

}

%enddef /* EXTEND_CUSTOMKERNEL */

#endif /* SWIG_PYTHON */
