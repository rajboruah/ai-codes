from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Cluster(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    cloud_provider = db.Column(db.String(20), nullable=False)  # 'aws' or 'azure'
    region = db.Column(db.String(50), nullable=False)
    kubernetes_version = db.Column(db.String(20), nullable=False)
    node_count = db.Column(db.Integer, nullable=False, default=2)
    instance_type = db.Column(db.String(50), nullable=False)
    status = db.Column(db.String(20), nullable=False, default='pending')  # pending, creating, running, failed, deleting
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    terraform_state_path = db.Column(db.String(255))
    cluster_endpoint = db.Column(db.String(255))
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'cloud_provider': self.cloud_provider,
            'region': self.region,
            'kubernetes_version': self.kubernetes_version,
            'node_count': self.node_count,
            'instance_type': self.instance_type,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'cluster_endpoint': self.cluster_endpoint
        }

