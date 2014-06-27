/*
 * generated by Xtext
 */
package fr.obeo.releng.targetplatform.validation

import com.google.common.base.Strings
import com.google.common.collect.LinkedHashMultimap
import com.google.common.collect.Lists
import com.google.common.collect.Multimaps
import com.google.common.collect.Sets
import com.google.inject.Inject
import fr.obeo.releng.targetplatform.Environment
import fr.obeo.releng.targetplatform.IU
import fr.obeo.releng.targetplatform.Location
import fr.obeo.releng.targetplatform.Option
import fr.obeo.releng.targetplatform.TargetPlatform
import fr.obeo.releng.targetplatform.TargetPlatformPackage
import fr.obeo.releng.targetplatform.util.LocationIndexBuilder
import java.net.URI
import java.util.List
import org.eclipse.core.runtime.NullProgressMonitor
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.equinox.p2.core.IProvisioningAgent
import org.eclipse.equinox.p2.metadata.VersionRange
import org.eclipse.equinox.p2.query.QueryUtil
import org.eclipse.equinox.p2.repository.metadata.IMetadataRepositoryManager
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.nodemodel.impl.CompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import org.eclipse.core.runtime.Platform
import org.eclipse.jdt.launching.JavaRuntime
import java.util.Locale
import fr.obeo.releng.targetplatform.services.TargetPlatformGrammarAccess

/**
 * Custom validation rules. 
 *
 * see http://www.eclipse.org/Xtext/documentation.html#validation
 */
class TargetPlatformValidator extends AbstractTargetPlatformValidator {

	@Inject
	LocationIndexBuilder indexBuilder;
	
	@Inject
	IProvisioningAgent provisioningAgent;
	
	@Inject 
	TargetPlatformGrammarAccess grammarAccess;
	
	public static val CHECK__OPTIONS_SELF_EXCLUDING_ALL_ENV_REQUIRED = "CHECK__OPTIONS_SELF_EXCLUDING_ALL_ENV_REQUIRED"
	
	public static val CHECK__OPTIONS_EQUALS_ALL_LOCATIONS = "CHECK__OPTIONS_EQUALS_ALL_LOCATIONS"
	public static val CHECK__NO_OPTIONS_ON_LOCATIONS_IF_GLOBAL_OPTIONS = "CHECK__NO_OPTIONS_ON_LOCATIONS_IF_GLOBAL_OPTIONS"
	
	public static val DEPRECATE__OPTIONS_ON_LOCATIONS = "DEPRECATE__OPTIONS_ON_LOCATIONS"
	public static val DEPRECATE__STRINGS_ON_IU_VERSION = "DEPRECATE__STRINGS_ON_IU_VERSION"
	
	public static val CHECK__LOCATION_CONFLICTUAL_ID = "CHECK__LOCATION_CONFLICTUAL_ID"
	public static val CHECK__INCLUDED_LOCATION_CONFLICTUAL_ID = "CHECK__INCLUDED_LOCATION_CONFLICTUAL_ID"
	public static val CHECK__CONFLICTUAL_ID__BETWEEN_INCLUDED_LOCATION = "CHECK__INCLUDED_LOCATION_CONFLICTUAL_ID"
	
	public static val CHECK__LOCATION_ID_UNIQNESS = "CHECK__LOCATION_ID_UNIQNESS"	
	public static val CHECK__INCLUDE_CYCLE = "CHECK__INCLUDE_CYCLE"
	public static val CHECK__IU_IN_LOCATION = "CHECK__IU_IN_LOCATION"
	public static val CHECK__LOCATION_URI = "CHECK__LOCATION_URI"
	public static val CHECK__ENVIRONMENT_VALIDITY = "CHECK__ENVIRONMENT_VALIDITY"
	public static val CHECK__ENVIRONMENT_UNICITY = "CHECK__ENVIRONMENT_UNICITY"
	public static val CHECK__ENVIRONMENT_COHESION = "CHECK__ENVIRONMENT_COHESION"
	
	public static val CHECK__ESCAPE_CHAR_IU_ID = " CHECK__ESCAPE_CHAR_IU_ID"
	public static val CHECK__VERSION_KEYWORDS = "CHECK__VERSION_KEYWORDS"
	
	@Check // TESTED
	def checkAllEnvAndRequiredAreSelfExluding(TargetPlatform targetPlatform) {
		doCheckAllEnvAndRequiredAreSelfExluding(targetPlatform, targetPlatform.options, TargetPlatformPackage.Literals.TARGET_PLATFORM__OPTIONS);
	}
	
	@Check // TESTED
	def checkAllEnvAndRequiredAreSelfExluding(Location location) {
		doCheckAllEnvAndRequiredAreSelfExluding(location, location.options, TargetPlatformPackage.Literals.LOCATION__OPTIONS)
	}
	
	private def doCheckAllEnvAndRequiredAreSelfExluding(EObject optionOwner, List<Option> options, EStructuralFeature feature) {
		if (options.contains(Option.INCLUDE_ALL_ENVIRONMENTS) && options.contains(Option.INCLUDE_REQUIRED)) {
			error("All environments can not be included along with required artifacts, you must choose one of the two options.", 
					optionOwner, 
					feature, 
					options.indexOf(Option.INCLUDE_REQUIRED), CHECK__OPTIONS_SELF_EXCLUDING_ALL_ENV_REQUIRED)
			
			error("All environments can not be included along with required artifacts, you must choose one of the two options.", 
					optionOwner, 
					feature, 
					options.indexOf(Option.INCLUDE_ALL_ENVIRONMENTS), CHECK__OPTIONS_SELF_EXCLUDING_ALL_ENV_REQUIRED)
		}
	}
	
	@Check // TESTED
	def checkNoLocationOptionIfGlobalOptions(Location location) {
		if (!location.options.empty && !(location.eContainer as TargetPlatform).options.empty) {
			val nodes = NodeModelUtils::findNodesForFeature(location, TargetPlatformPackage.Literals.LOCATION__OPTIONS)
			val withKeyword = (nodes.head as CompositeNode).previousSibling
			val lastOption = (nodes.last as CompositeNode);
			acceptError("You can not define options on location and on target platform.",
				location, withKeyword.offset, lastOption.endOffset - withKeyword.offset, CHECK__NO_OPTIONS_ON_LOCATIONS_IF_GLOBAL_OPTIONS)
		}
	}
	
	@Check // TESTED
	def checkOptionsOnLocationAreIdentical(TargetPlatform targetPlatform) {
		if (targetPlatform.options.empty) { // else do not check as it is another error.
			val listOptions = targetPlatform.locations
			val first = listOptions.head
			val conflicts = listOptions.tail.filter[_| !Sets::symmetricDifference(_.options.toSet,first.options.toSet).empty]
			if (!conflicts.empty) {
				listOptions.forEach[_ |
					val nodes = NodeModelUtils::findNodesForFeature(_, TargetPlatformPackage.Literals.LOCATION__OPTIONS)
					if (!nodes.empty) {
						val withKeyword = (nodes.head as CompositeNode).previousSibling
						val lastOption = (nodes.last as CompositeNode)
						acceptError("Options of every locations must be the same",
							_, withKeyword.offset, lastOption.endOffset - withKeyword.offset, CHECK__OPTIONS_EQUALS_ALL_LOCATIONS)
					} else {
						val node = NodeModelUtils::getNode(_)
						acceptError("Options of every locations must be the same",
							_, node.offset, node.length, CHECK__OPTIONS_EQUALS_ALL_LOCATIONS)
					}
				]
			}
		}
	}
	
	@Check // TESTED
	def deprecateOptionsOnLocation(Location location) {
		val targetPlatform = location.eContainer as TargetPlatform
		
		if (targetPlatform.options.empty && !location.options.empty) {
			val nodes = NodeModelUtils::findNodesForFeature(location, TargetPlatformPackage.Literals.LOCATION__OPTIONS)
			val withKeyword = (nodes.head as CompositeNode).previousSibling
			val lastOption = (nodes.last as CompositeNode);
			acceptWarning("Options on location are deprecated. Define the option at the target level.",
				location, withKeyword.offset, lastOption.endOffset - withKeyword.offset, DEPRECATE__OPTIONS_ON_LOCATIONS)
		}
	}
	
	@Check // TESTED
	def deprecateIUVersionRangeWihString(IU iu) {
		if (iu.version != null) {
			val nodes = NodeModelUtils::findNodesForFeature(iu, TargetPlatformPackage.Literals.IU__VERSION)
			if ("STRING".equals((nodes.head.grammarElement as RuleCall).rule.name)) {
				warning("Usage of strings is deprecated for version range. You should remove the quotes.",
					iu, 
					TargetPlatformPackage.Literals.IU__VERSION,
					DEPRECATE__STRINGS_ON_IU_VERSION)
			}
		}
	}

	@Check // TESTED
	def checkIDUniqueOnAllLocations(TargetPlatform targetPlatform) {
		val locationsByURI = indexBuilder.getLocationIndex(targetPlatform)
		val resource = targetPlatform.eResource
		
		val locationIDsByURI = LinkedHashMultimap.create();  
		locationsByURI.keySet.forEach[
			locationIDsByURI.putAll(it, locationsByURI.get(it).map[ID].toSet)
		]
		
		val locationsURIWithoutConflictingID = locationIDsByURI.asMap.filter[key,value|value.size <= 1].keySet
		val locationsWithoutConflictingID = locationsURIWithoutConflictingID.map[locationsByURI.get(it)].flatten
		
		val locationsWithoutConflictingIDByID = Multimaps.index(locationsWithoutConflictingID.filter[ID!=null], [ID])
		val locationsWithDuplicateID = locationsWithoutConflictingIDByID.asMap.filter[key,value|value.map[uri].toSet.size > 1].values.flatten
		locationsWithDuplicateID.forEach[location|
			if (location.eResource == resource) {
				error('ID must be unique for each location', 
					location,
					TargetPlatformPackage.Literals.LOCATION__ID, 
					CHECK__LOCATION_ID_UNIQNESS
				)
			} else {
				val conflictualInclude = targetPlatform.includes.filter[
					val direct = indexBuilder.getImportedTargetPlatform(resource, it);
					direct.locations.contains(location) ||
					indexBuilder.getImportedTargetPlatforms(direct).map[locations].flatten.toSet.contains(location)
				].toSet
				
				conflictualInclude.forEach[
					error('''ID '«location.ID»' is duplicated in the included target platform''', 
						it, 
						TargetPlatformPackage.Literals.INCLUDE_DECLARATION__IMPORT_URI,
						CHECK__LOCATION_ID_UNIQNESS
					)
				]
			}
		]
	}
	
	@Check // TESTED
	def checkImportCycle(TargetPlatform targetPlatform) {
		val cycle = indexBuilder.checkIncludeCycle(targetPlatform)
		if (!cycle.empty) {
			val cyclingImport = targetPlatform.includes.findFirst[cycle.get(1).equals(indexBuilder.getImportedTargetPlatform(targetPlatform.eResource, it))]
			if (cyclingImport != null) {
				error('''Cycle detected in the included target platforms. Cycle is '«cycle.drop(1).map[eResource.URI].join("'' -> '")»'.''', 
					cyclingImport, 
					TargetPlatformPackage.Literals.INCLUDE_DECLARATION__IMPORT_URI,
					CHECK__INCLUDE_CYCLE
				)
			}
		}
	}
	
	@Check // PARTIALLY TESTED
	def checkSameIDForAllLocationWithSameURI(TargetPlatform targetPlatform) {
		val locationsByURI = indexBuilder.getLocationIndex(targetPlatform)
		val resource = targetPlatform.eResource
		
		for (locationURI : locationsByURI.keySet) {
			val externalLocations = locationsByURI.get(locationURI).filter[eResource != resource]
			val externalIDs = externalLocations.map[Strings.nullToEmpty(ID)].toSet
			
			val internalLocations = locationsByURI.get(locationURI).filter[eResource == resource]
			val internalIDs = internalLocations.map[Strings.nullToEmpty(ID)].toSet
			
			if (externalIDs.size > 1) {
				val externalLocationsWithConflictualID = externalLocations.filter[externalIDs.contains(ID)]
				val String msg = '''The ID for location '«locationURI»' must be unique. Found '«externalIDs.join("', '")»'  in '«externalLocationsWithConflictualID.map[eResource.URI.toString].toSet.join("', '")»'.''';
				val conflictualInclude = externalLocationsWithConflictualID.map[location|
					targetPlatform.includes.filter[
						val direct = indexBuilder.getImportedTargetPlatform(resource, it);
						direct.locations.contains(location) ||
						indexBuilder.getImportedTargetPlatforms(direct).map[locations].flatten.toSet.contains(location)
					]
				].flatten.toSet
				
				conflictualInclude.forEach[
					error(msg, 
						it, 
						TargetPlatformPackage.Literals.INCLUDE_DECLARATION__IMPORT_URI,
						CHECK__CONFLICTUAL_ID__BETWEEN_INCLUDED_LOCATION
					)
				]
			}  

			if (externalIDs.size == 1) {
				val diff = Sets.symmetricDifference(externalIDs, internalIDs);
				if (!diff.empty) {
					val String msg = '''
						The ID for location '«locationURI»' must be unique across included target platforms and the current one. Found '«externalIDs.head»'  in '«externalLocations.map[eResource.URI.toString].toSet.join("', '")»'.
					''';
					
					internalLocations.filter[!externalIDs.contains(Strings.nullToEmpty(ID))].forEach[
						error(msg, it, TargetPlatformPackage.Literals.LOCATION__ID, CHECK__INCLUDED_LOCATION_CONFLICTUAL_ID, externalIDs.head, externalLocations.head.uri)
					]
				}
			} 
			
			if (externalIDs.size < 1 && internalIDs.size > 1) {
				val msg = '''The ID for location '«locationURI»' must be unique. Found '«internalIDs.join("', '")»'.''';
				internalLocations.forEach[
					error(msg, it, TargetPlatformPackage.Literals.LOCATION__ID, CHECK__LOCATION_CONFLICTUAL_ID)
				]
			}
		}
	}
	
	@Check(value=CheckType.EXPENSIVE)
	def checkLocationURI(Location location) {
		if (!location.uri.nullOrEmpty) {
			val repositoryManager = provisioningAgent.getService(IMetadataRepositoryManager.SERVICE_NAME) as IMetadataRepositoryManager
			try {
				repositoryManager.loadRepository(new URI(location.uri), new NullProgressMonitor)
			} catch (Exception e) {
				error(e.message, location, TargetPlatformPackage.Literals.LOCATION__URI, CHECK__LOCATION_URI)
			}
		}
	}
	
	@Check(value=CheckType.EXPENSIVE)
	def checkIUIDAndRangeInRepository(IU iu) {
		val repositoryManager = provisioningAgent.getService(IMetadataRepositoryManager.SERVICE_NAME) as IMetadataRepositoryManager
		val metadataRepository = repositoryManager.loadRepository(new URI((iu.eContainer as Location).uri), new NullProgressMonitor)
		val idResults = metadataRepository.query(QueryUtil.createIUQuery(iu.ID), new NullProgressMonitor).toUnmodifiableSet()
		if (idResults.empty) {
			error('''No installable unit with ID '«iu.ID»' can be found in '«(iu.eContainer as Location).uri»'.''', iu, TargetPlatformPackage.Literals.IU__ID, CHECK__IU_IN_LOCATION)
		} else if (!iu.version.nullOrEmpty && !"lazy".equals(iu.version)) {
			val versionResult = metadataRepository.query(QueryUtil.createQuery("latest(x | x.id == $0 && x.version ~= $1)", iu.ID, new VersionRange(iu.version)), new NullProgressMonitor)
			if (versionResult.empty) {
				error('''No installable unit with ID '«iu.ID»' can be found with range constraint '«iu.version»'.''', iu, TargetPlatformPackage.Literals.IU__VERSION, CHECK__IU_IN_LOCATION)
			}
		}
	}
	
	@Check
	def checkEnvironment(Environment env) {
		val dupEnv = Lists.newArrayList(env.env)
		val dupEnvIt = dupEnv.iterator 
		
		val knownOSUpperValues = Platform.knownOSValues.map[toUpperCase]
		val knownWSUpperValues = Platform.knownWSValues.map[toUpperCase]
		val knownArchUpperValues = Platform.knownOSArchValues.map[toUpperCase]
		val knownLocale = Locale.availableLocales.map[toString].map[toUpperCase]
		val knownEE = JavaRuntime.executionEnvironmentsManager.executionEnvironments.map[id.toUpperCase]
		
		while(dupEnvIt.hasNext) {
			val envValue = dupEnvIt.next.toUpperCase
			if (knownOSUpperValues.contains(envValue) ||
				knownWSUpperValues.contains(envValue) ||
				knownArchUpperValues.contains(envValue) ||
				knownLocale.contains(envValue) ||
				knownEE.contains(envValue)) {
				dupEnvIt.remove	
			}
		}
		
		for(String errorEnv: dupEnv) {
			error(''''«errorEnv»' is not a valid environment specification value.''', 
					env, 
					TargetPlatformPackage.Literals.ENVIRONMENT__ENV, 
					env.env.indexOf(errorEnv), CHECK__ENVIRONMENT_VALIDITY)
		}
	}
	
	@Check
	def checkOneEnvironment(TargetPlatform tp) {
		val envList = tp.contents.filter(typeof(Environment)).toList
		if (envList.size > 1) {
			envList.tail.forEach[
				warning('''Environment definition should not be splitted accros the file.''', tp, TargetPlatformPackage.Literals.TARGET_PLATFORM__CONTENTS, tp.contents.indexOf(it), CHECK__ENVIRONMENT_UNICITY)
			]
		}
	}
	
	@Check
	def checkEnvironmentCohesion(TargetPlatform tp) {
		val tpEnv = tp.environment
	
		val knownOSUpperValues = Platform.knownOSValues.map[toUpperCase]
		val knownWSUpperValues = Platform.knownWSValues.map[toUpperCase]
		val knownArchUpperValues = Platform.knownOSArchValues.map[toUpperCase]
		val knownLocale = Locale.availableLocales.map[toString.toUpperCase]
		val knownEE = JavaRuntime.executionEnvironmentsManager.executionEnvironments.map[id.toUpperCase]
		
		val envList = tp.contents.filter(typeof(Environment)).map[env].flatten.filter[!nullOrEmpty].toList
		
		val allOS = envList.filter[!toUpperCase.equals(tpEnv.windowingSystem?.toUpperCase)].filter[knownOSUpperValues.contains(it.toUpperCase)].toList
		val allWS = envList.filter[!toUpperCase.equals(tpEnv.operatingSystem?.toUpperCase)].filter[knownWSUpperValues.contains(it.toUpperCase)].toList
		val allArch = envList.filter[knownArchUpperValues.contains(it.toUpperCase)].toList
		val allLocale = envList.filter[knownLocale.contains(it.toUpperCase)].toList
		val allEE = envList.filter[knownEE.contains(it.toUpperCase)].toList
		
		if (allOS.size > 1) {
			allOS.forEach[e|
				tp.contents.filter(typeof(Environment)).filter[env.contains(e)].forEach[env|
					error('''Cannot define multiple operating system.''', env, TargetPlatformPackage.Literals.ENVIRONMENT__ENV, env.env.indexOf(e), CHECK__ENVIRONMENT_COHESION)
				]
			]
		}
		
		if (allWS.size > 1) {
			allWS.forEach[e|
				tp.contents.filter(typeof(Environment)).filter[env.contains(e)].forEach[env|
					error('''Cannot define multiple windowing system.''', env, TargetPlatformPackage.Literals.ENVIRONMENT__ENV, env.env.indexOf(e), CHECK__ENVIRONMENT_COHESION)
				]
			]
		}
		
		if (allArch.size > 1) {
			allArch.forEach[e|
				tp.contents.filter(typeof(Environment)).filter[env.contains(e)].forEach[env|
					error('''Cannot define multiple architecture.''', env, TargetPlatformPackage.Literals.ENVIRONMENT__ENV, env.env.indexOf(e), CHECK__ENVIRONMENT_COHESION)
				]
			]
		}
		
		if (allLocale.size > 1) {
			allLocale.forEach[e|
				tp.contents.filter(typeof(Environment)).filter[env.contains(e)].forEach[env|
					error('''Cannot define multiple locale.''', env, TargetPlatformPackage.Literals.ENVIRONMENT__ENV, env.env.indexOf(e), CHECK__ENVIRONMENT_COHESION)
				]
			]
		}
		
		if (allEE.size > 1) {
			allEE.forEach[e|
				tp.contents.filter(typeof(Environment)).filter[env.contains(e)].forEach[env|
					error('''Cannot define multiple execution environment.''', env, TargetPlatformPackage.Literals.ENVIRONMENT__ENV, env.env.indexOf(e), CHECK__ENVIRONMENT_COHESION)
				]
			]
		}
	}
	
	@Check
	def checkNoEscapeCharacterInIUID(IU iu) {
		val node = NodeModelUtils.getNode(iu)
		val idRule = node.asTreeIterable.findFirst[
			grammarElement == grammarAccess.IUAccess.IDIDTerminalRuleCall_0_0
		]
		
		val id =
			if (idRule.text.startsWith('^')) {
				idRule.text.substring(1)
			} else {
				idRule.text
			}
		if (id.contains('^')) {
			warning('''Usage of escape character '^' in the ID of IUs is not required anymore and has been deprecated.''', iu, TargetPlatformPackage.Literals.IU__ID, CHECK__ESCAPE_CHAR_IU_ID)
		}
	}
	
	@Check
	def checkVersionKeywords(IU iu) {
		val node = NodeModelUtils.getNode(iu)
		val semicolonKeywordRule = node.asTreeIterable.findFirst[grammarElement == grammarAccess.IUAccess.semicolonKeyword_1_0_0]
		val equalSignKeywordRule = node.asTreeIterable.findFirst[grammarElement == grammarAccess.IUAccess.equalsSignKeyword_1_0_2]
		
		if (semicolonKeywordRule != null) {
			acceptWarning("Usage of keywords ';version=' are not required anymore and has been deprecated.", iu, semicolonKeywordRule.offset, equalSignKeywordRule.endOffset-semicolonKeywordRule.offset, CHECK__VERSION_KEYWORDS)
		}
	}
}
