module Cdn77 where

import Affjax (Response)
import Affjax (get, post) as AffJax
import Affjax.RequestBody (formURLEncoded) as RequestBody
import Affjax.ResponseFormat as ResponseFormat
import Control.Applicative (pure)
import Control.Apply ((*>))
import Control.Category ((<<<))
import Control.Monad.Except (ExceptT, except)
import Data.Argonaut.Core (Json)
import Data.Either (Either)
import Data.FormURLEncoded (encode)
import Data.Function (const, ($))
import Data.Semigroup ((<>))
import Data.Unit (Unit, unit)
import Debug.Trace (trace)
import Effect.Aff (Aff)
import Simple.JSON (class ReadForeign, class WriteForeign)
import Types (ApiCallError, ApiRequest, ApiRequestUrl, CDNResourceDetails, CdnId, Report, ReportType, RequestId, RequestType, Storage, StorageId, Timestamp)
import Utils (readResponsesCustomObject, readStandardResponse, urlEncoded)
import Utils as Utils

apiUrl ∷ String
apiUrl = "https://api.cdn77.com/v2.0"


get ∷ ∀ p. WriteForeign { | p } ⇒ String → { | p } → Aff (Response (Either ResponseFormat.ResponseFormatError Json))
get endpoint params = AffJax.get ResponseFormat.json $
 let u = apiUrl <> endpoint <> "?" <> encode (urlEncoded params)
 in trace u $ const u


post ∷ ∀ p. WriteForeign { | p } ⇒ String → { | p } → Aff (Response (Either ResponseFormat.ResponseFormatError Json))
post endpoint params = AffJax.post ResponseFormat.json (apiUrl <> endpoint) (RequestBody.formURLEncoded $
  let u = urlEncoded params
  in trace (encode u) $ const u)


readJson ∷ ∀ a. ReadForeign a ⇒ Json → ExceptT ApiCallError Aff a
readJson = except <<< Utils.readJson

-------------------------------------------------------
--------------------- CDNResources --------------------

listCdnResources
  ∷ { login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff (Array CDNResourceDetails)
listCdnResources params = readResponsesCustomObject "cdnResources" (get "/cdn-resource/list" params)

getCdnResourceDetails
  ∷ { id ∷ CdnId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff CDNResourceDetails
getCdnResourceDetails params = readResponsesCustomObject "cdnResource" (get "/cdn-resource/details" params)

-------------------------------------------------------
------------------------ DATA -------------------------

prefetch
  ∷ { login ∷ String, passwd ∷ String, cdn_id ∷ CdnId, url ∷ Array String }
  → ExceptT ApiCallError Aff {url ∷ Array String, request_id ∷ RequestId }
prefetch params = readResponsesCustomObject "cdnResource" (post "/data/prefetch" params)

purge
  ∷ { url ∷ Array String, cdn_id ∷ CdnId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff {url ∷ Array String, request_id ∷ RequestId }
purge params = readResponsesCustomObject "cdnResource" (post "/data/purge" params)

purgeAll
  ∷ { cdn_id ∷ CdnId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff Unit
purgeAll params = readStandardResponse (post "/data/purge-all" params) *> pure unit

--------------------------------------------------------
---------------------- DATA QUEUE ----------------------

listRequests
  ∷ { type ∷ RequestType, cdn_id ∷ CdnId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff (Array ApiRequest)
listRequests params = readResponsesCustomObject "requests" (get "/data-queue/list-request" params)

getRequestDetails
  ∷ { id ∷ RequestId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff ApiRequest
getRequestDetails params = readResponsesCustomObject "request" (get "/data-queue/details-request" params)

listRequestUrl
  ∷ { request_id ∷ RequestId, cdn_id ∷ CdnId, login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff ApiRequestUrl
listRequestUrl params = readResponsesCustomObject "urls" (get "/data-queue/list-url" params)


--------------------------------------------------------
------------------------ STORAGE -----------------------

createStorage
  ∷ { login ∷ String, passwd ∷ String, zone_name ∷ String, storage_location_id ∷ String }
  → ExceptT ApiCallError Aff Storage
createStorage params = readResponsesCustomObject "storage" (post "/storage/create" params)

storageDetails
  ∷ { login ∷ String, passwd ∷ String, id ∷ StorageId }
  → ExceptT ApiCallError Aff Storage
storageDetails params = readResponsesCustomObject "storage" (get "/storage/details" params)

deleteStorage
  ∷ { login ∷ String, passwd ∷ String, id ∷ StorageId }
  → ExceptT ApiCallError Aff Unit
deleteStorage params = readStandardResponse (post "/storage/delete" params) *> pure unit

listStorages
  ∷ { login ∷ String, passwd ∷ String }
  → ExceptT ApiCallError Aff (Array Storage)
listStorages params = readResponsesCustomObject "storages" (get "/storage/list" params)

addStorageCdnResources
  ∷ { login ∷ String, passwd ∷ String, id ∷ StorageId, cdn_ids ∷ Array CdnId }
  → ExceptT ApiCallError Aff Unit
addStorageCdnResources params = readStandardResponse (post "/storage/add-cdn-resource" params) *> pure unit


--------------------------------------------------------
------------------------ REPORT -----------------------

reportDetails
  ∷ { login ∷ String, passwd ∷ String, type ∷ ReportType
    , from ∷ Timestamp, to ∷ Timestamp, cdn_ids ∷ Array CdnId}
  → ExceptT ApiCallError Aff Report
reportDetails params = readResponsesCustomObject "report" (get "/report/details" params)
