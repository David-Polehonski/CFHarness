component accessors=true output=false persistent=false {

	property string observerId;

	public Observer function init (required string observerId) output='false' {
		this.setObserverId( arguments.observerId );
		return this;
	}

	public array function retrieveCalls () output='false' {
		if(this.getObserverId() != 0) {
			var observations = cfharness.core.MockService::retrieveCalls( this.getObserverId() );
			return observations;
		} else {
			throw( 'Observer has been detached from service session' );
		}
	}

	public void function disregard () output='false' {
		if(this.getObserverId() != 0) {
			cfharness.core.MockService::disregard( this.getObserverId() );
			this.setObserverId( 0 );
		} else {
			throw( 'Observer has been detached from service session' );
		}
	}


}
