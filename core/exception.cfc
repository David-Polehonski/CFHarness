component name="exception" output="false" {
	public testException function init(required string message, required string detail, required string errorCode) {
		this.type='exception';
		this.errorCode='';
		this.message='';
		this.detail='';
	}
}
