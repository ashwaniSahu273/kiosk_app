/// Marker interface for organization-scoped content.
///
/// Any model that belongs to a specific [Organization] implements this so the
/// [OrganizationContext] can filter mixed-tenant lists down to the active org.
abstract class OrgOwned {
  /// Identifier of the organization that owns this item.
  String get organizationId;
}
