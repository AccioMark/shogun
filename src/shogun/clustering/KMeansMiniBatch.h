/*
 * This software is distributed under BSD 3-clause license (see LICENSE file).
 *
 * Authors: Saurabh Mahindre, Heiko Strathmann
 */

#ifndef _MBKMEANS_H__
#define _MBKMEANS_H__

#include <shogun/lib/config.h>

#include <shogun/lib/common.h>
#include <shogun/io/SGIO.h>
#include <shogun/distance/Distance.h>
#include <shogun/machine/DistanceMachine.h>
#include <shogun/clustering/KMeansBase.h>

namespace shogun
{
class CKMeansBase;
	
/** Class for the mini batch KMeans */
class CKMeansMiniBatch : public CKMeansBase
{
	public:
		/** default constructor */
		CKMeansMiniBatch();

		/** constructor
		 *
		 * @param k parameter k
		 * @param d distance
		 * @param kmeanspp true for using KMeans++ (default false)
		 */
		CKMeansMiniBatch(int32_t k, CDistance* d, bool kmeanspp=false);

		/** constructor for supplying initial centers
		 * @param k_i parameter k
		 * @param d_i distance
		 * @param centers_i initial centers for KMeans aloverride private method c++gorithm
		*/
		CKMeansMiniBatch(int32_t k_i, CDistance* d_i, SGMatrix<float64_t> centers_i);
		
		virtual ~CKMeansMiniBatch();

		/** @return object name */
		virtual const char* get_name() const
		{
			return "KMeansMiniBatch";
		}

	protected:

		/** train k-means
		 *
		 * @param data training data (parameter can be avoided if distance or
		 * kernel-based classifiers are used and distance/kernels are
		 * initialized with train data)
		 *
		 * @return whether training was successful
		 */
		virtual bool train_machine(CFeatures* data=NULL);

		/** mini-batch KMeans training method
		 */
		void minibatch_KMeans();

	private:

		void init_mb_params();

		/* choose b integers between 0 and num-1
		 *
		 */
		SGVector<int32_t> mbchoose_rand(int32_t b, int32_t num);

	protected:

		/** Batch size for mini-batch KMeans */
		int32_t batch_size;
};
}
#endif
