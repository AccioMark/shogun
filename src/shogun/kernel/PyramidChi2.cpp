/*
 * This software is distributed under BSD 3-clause license (see LICENSE file).
 *
 * Authors: Soeren Sonnenburg, Evan Shelhamer, Sergey Lisitsyn
 */

#include <shogun/kernel/PyramidChi2.h>
#include <shogun/lib/common.h>
#include <shogun/kernel/GaussianKernel.h>
#include <shogun/features/Features.h>
#include <shogun/io/SGIO.h>
#include <shogun/mathematics/Math.h>
#include <shogun/mathematics/UniformIntDistribution.h>

using namespace shogun;

CPyramidChi2::CPyramidChi2()
: weights(NULL)
{
	// this will produce an erro in kernel computation!
	num_cells=0;
	width_computation_type=0;
	width=1;
	num_randfeats_forwidthcomputation=-1;
}

CPyramidChi2::CPyramidChi2(
	int32_t size, int32_t num_cells2,
		float64_t* weights_foreach_cell2,
		int32_t width_computation_type2,
		float64_t width2)
: RandomMixin<CDotKernel>(size), num_cells(num_cells2),weights(NULL),
width_computation_type(width_computation_type2), width(width2),
	 num_randfeats_forwidthcomputation(-1)
{
	if(num_cells<=0)
		error("CPyramidChi2 Constructor fatal error: parameter num_cells2 NOT positive");
	weights=SG_MALLOC(float64_t, num_cells);
	if(weights_foreach_cell2)
	{
		for (int32_t i=0; i<num_cells; ++i)
			weights[i]=weights_foreach_cell2[i];
	}
	else
	{	for (int32_t i=0; i<num_cells; ++i)
			weights[i]=1;
	}

	if (width_computation_type>0 )
	{
		num_randfeats_forwidthcomputation=(int32_t)CMath::round(width);
		width=-1;
	}


}

void CPyramidChi2::cleanup()
{
	// this will produce an erro in kernel computation!
	num_cells=0;
	width_computation_type=0;
	width=1;

	num_randfeats_forwidthcomputation=-1;

	SG_FREE(weights);
	weights=NULL;

	CKernel::cleanup();
}

bool CPyramidChi2::init(CFeatures* l, CFeatures* r)
{
	CDotKernel::init(l, r);
	return init_normalizer();
}

CPyramidChi2::CPyramidChi2(
	CDenseFeatures<float64_t>* l, CDenseFeatures<float64_t>* r,
		int32_t size, int32_t num_cells2,
		float64_t* weights_foreach_cell2,
		int32_t width_computation_type2,
		float64_t width2)
: RandomMixin<CDotKernel>(size), num_cells(num_cells2), weights(NULL),
width_computation_type(width_computation_type2), width(width2),
	  num_randfeats_forwidthcomputation(-1)
{
	if(num_cells<=0)
		error("CPyramidChi2 Constructor fatal error: parameter num_cells2 NOT positive");
	weights=SG_MALLOC(float64_t, num_cells);
	if(weights_foreach_cell2)
	{
		for (int32_t i=0; i<num_cells; ++i)
			weights[i]=weights_foreach_cell2[i];
	}
	else
	{	for (int32_t i=0; i<num_cells; ++i)
			weights[i]=1;
	}

	if (width_computation_type>0 )
	{
		num_randfeats_forwidthcomputation=(int32_t)CMath::round(width);
		width=-1;
	}

	init(l, r);
}

CPyramidChi2::~CPyramidChi2()
{
	cleanup();
}



float64_t CPyramidChi2::compute(int32_t idx_a, int32_t idx_b)
{

	if(num_cells<=0)
		error("CPyramidChi2::compute(...) fatal error: parameter num_cells NOT positive");

	int32_t alen, blen;
	bool afree, bfree;

	float64_t* avec=((CDenseFeatures<float64_t>*) lhs)->get_feature_vector(idx_a,
					alen, afree);
	float64_t* bvec=((CDenseFeatures<float64_t>*) rhs)->get_feature_vector(idx_b,
					blen, bfree);
	if(alen!=blen)
		error("CPyramidChi2::compute(...) fatal error: lhs feature dim != rhs feature dim");

	int32_t dims=alen/num_cells;


	if(width<=0)
	{
		if(width_computation_type >0)
		{

			//compute width
			int32_t numind;

			if (num_randfeats_forwidthcomputation >1)
			{
				numind=CMath::min( ((CDenseFeatures<float64_t>*) lhs)->get_num_vectors() , num_randfeats_forwidthcomputation);
			}
			else
			{
				numind= ((CDenseFeatures<float64_t>*) lhs)->get_num_vectors();
			}
			float64_t* featindices = SG_MALLOC(float64_t, numind);

			if (num_randfeats_forwidthcomputation >0)
			{
				random::fill_array(
					featindices, featindices + numind, 0,
					((CDenseFeatures<float64_t>*) lhs)->get_num_vectors()-1, m_prng);
			}
			else
			{
				for(int32_t i=0; i< numind;++i)
					featindices[i]=i;
			}


			width=0;

			//get avec, get bvec	only from lhs, do not free
			for (int32_t li=0; li < numind;++li)
			{
				avec=((CDenseFeatures<float64_t>*) lhs)->get_feature_vector(featindices[li],
					alen, afree);
				for (int32_t ri=0; ri <=li;++ri)
				{
					// lhs is right here!!!
					bvec=((CDenseFeatures<float64_t>*) lhs)->get_feature_vector(featindices[ri],
							blen, bfree);

					float64_t result=0;
					for (int32_t histoind=0; histoind<num_cells; ++histoind)
					{
						float64_t curweight=weights[histoind];

						for (int32_t i=0; i< dims; ++i)
						{
							int32_t index= histoind*dims+i;
							if(avec[index] + bvec[index]>0)
							{
								result+= curweight*(avec[index] - bvec[index])*(avec[index]
									- bvec[index])/(avec[index] + bvec[index]);
							}
						}
					}
					width+=result*2.0/((double)numind)/(numind+1.0);
				}

			}
			SG_FREE(featindices);
		}
		else
		{
			error("CPyramidChi2::compute(...) fatal error: width<=0");
		}
	}


	//the actual kernel computation
	avec=((CDenseFeatures<float64_t>*) lhs)->get_feature_vector(idx_a,
					alen, afree);
	bvec=((CDenseFeatures<float64_t>*) rhs)->get_feature_vector(idx_b,
					blen, bfree);

	float64_t result=0;
	for (int32_t histoind=0; histoind<num_cells; ++histoind)
	{
		float64_t curweight=weights[histoind];

		for (int32_t i=0; i< dims; ++i)
		{
			int32_t index= histoind*dims+i;
			if(avec[index] + bvec[index]>0)
			{
				result+= curweight*(avec[index] - bvec[index])*(avec[index]
					- bvec[index])/(avec[index] + bvec[index]);
			}
		}
	}
	result = std::exp(-result / width);

	((CDenseFeatures<float64_t>*) lhs)->free_feature_vector(avec, idx_a, afree);
	((CDenseFeatures<float64_t>*) rhs)->free_feature_vector(bvec, idx_b, bfree);

	return (result);
}

void CPyramidChi2::setparams_pychi2(int32_t num_cells2,
		float64_t* weights_foreach_cell2,
		int32_t width_computation_type2,
		float64_t width2)
{
	num_cells=num_cells2;
	width_computation_type=width_computation_type2;
	width=width2;
	num_randfeats_forwidthcomputation=-1;

	if(num_cells<=0)
		error("CPyramidChi2::setparams_pychi2(...) fatal error: parameter num_cells2 NOT positive");
	if(weights)
		SG_FREE(weights);
	weights=SG_MALLOC(float64_t, num_cells);
	if(weights_foreach_cell2)
	{
		for (int32_t i=0; i<num_cells; ++i)
			weights[i]=weights_foreach_cell2[i];
	}
	else
	{	for (int32_t i=0; i<num_cells; ++i)
			weights[i]=1;
	}

	if (width_computation_type>0 )
	{
		num_randfeats_forwidthcomputation=(int32_t)CMath::round(width);
		width=-1;
	}
}
