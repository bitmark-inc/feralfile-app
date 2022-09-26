const XTZ_GETBACK_ADDRESS = 'tz1Td5qwQxz5mDZiwk7TsRGhDU2HBvXgULip';
const IMAGE_ARTWORK = 'Kamisaki';
const VIDEO_ARTWORK = 'Caught Red Handed';
const ARTWORK_4 = 'EVOLVE Magazine Issue 03';
const ARTWORK_5 = 'To make a botanist cry #266';
const ARTWORK_6 = '100';
const ARTWORK_LOADING_TIME_LIMIT = 5; //second
const LIST_CHECK_ARTWORKS = [
  'Kamisaki',
  'Caught Red Handed',
  '645_eflt_dorian432hz (^._.^)ﾉ',
  'EVOLVE Magazine Issue 03',
  'To make a botanist cry #266',
  '100',
  'WORDLE demolition!',
  'Space Shuttle Discovery',
  'Tezosaurus #11 - Gift for our fans',
];

const LIST_CHECK_ARTWORKSID_ADD_MANUAL = [
  'tez-KT1U6EHmNxJTkvaWJ4ThczG4FSDaHC21ssvi-873515',
  'tez-KT1TG3hqXr5Emip4KBbijKP9LM5hmCCjE2HM-2',
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-757148',
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-759675',
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-761761',
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-693627',
  //'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-633068',
  //'tez-KT1KXXZ758wtyf2NBjWKPeXugDh5Mm7kyckw-10',
];

const IS_INTERACTIVE_ARTWORK = {
  'tez-KT1U6EHmNxJTkvaWJ4ThczG4FSDaHC21ssvi-873515': false,//
  'tez-KT1TG3hqXr5Emip4KBbijKP9LM5hmCCjE2HM-2': false,//
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-757148': true,//
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-759675': true,
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-761761': true,//
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-693627': true,
  'tez-KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton-633068': false,
  'tez-KT1KXXZ758wtyf2NBjWKPeXugDh5Mm7kyckw-10': false,
};

const SEEDS_TO_RESTORE_FULLACCOUNT =
    'spin toward remind wagon flame hen sell tragic hundred verb culture believe';

const SEED_TO_RESTORE_KUKAI =
    'boring unveil betray damage idea educate entry cruise elevator hair cabin scatter royal alpha bicycle trade bonus stock just youth effort skate flash remember';
const SEED_TO_RESTORE_TEMPLE =
    'hidden laundry process risk unveil merge pyramid arrange hollow jeans motion scrap';

const LIST_OF_EXCHANGES = [
  {"exchangeName": 'objkt.com', "linkedExchangeName": 'objkt.com'},
  {'exchangeName': 'fxhash.xyz', 'linkedExchangeName': 'fxhash'},
  {'exchangeName': 'hicetnunc.cc', 'linkedExchangeName': 'hicetnunc.xyz'},
  {'exchangeName': 'teia.art', 'linkedExchangeName': 'teia.art'},
  {'exchangeName': 'versum.xyz', 'linkedExchangeName': 'versum'},
  {'exchangeName': 'akaswap.com', 'linkedExchangeName': 'akaswap'},
  {'exchangeName': 'typed.art', 'linkedExchangeName': 'typed.art'},
  {'exchangeName': 'feralfile.staging.bitmark.com/exhibitions', 'linkedExchangeName':'Feral File'},
];


const TEZ_SOURCE_ADDRESS = "tz1SidNQb9XcwP7L3MzCZD9JHmWw2ebDzgyX";
const TEZ_TARGET_ADDRESS = "tz1LVCTxttjxVPmZEfBatmXk8uT5S9CKmMUr";
const TEZ_SEND_ARTWORK_NAME = "Cay luoi ho cua Long";
const URL_BALANCE_SOURCE_ACCOUNT =
    "https://api.tzkt.io/v1/tokens/balances?account=$TEZ_SOURCE_ADDRESS&token.metadata.artifactUri.null=false&sort.desc=balance&limit=1";

const SUPPORT_SUB_MENU = [
  'Request a feature',
  'Report a bug',
  'Share feedback',
  'Something else',
];

const ALIAS_ACCOUNT = "ACOUNT_A";
const ALIAS_ANOTHER_ACCOUNT = "ACOUNT_B";
const SEED_TO_RESTORE_ACCOUNT =
    "real cat erase wrong shine example pen science barrel shed gentle tilt";
const SEED_TO_RESTORE_ANOTHER_ACCOUNT =
    "pair copper together wife riot lawn extend rebuild universe brain local easy";


const DEPOSIT_AMOUNT = 0.1;
const EPS = 2e-4;
