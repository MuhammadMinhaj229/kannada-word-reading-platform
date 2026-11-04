import Link from "next/link";
export default function OfflinePage() {
  return <main className="offline-page"><section className="offline-card">
    <div className="brand-mark">ಪ</div><p className="eyebrow">OFFLINE MODE</p>
    <h1>ಸಂಪರ್ಕ ಲಭ್ಯವಿಲ್ಲ</h1>
    <p>The application shell is available offline. Reopen ಪದLab after its first successful online load.</p>
    <Link className="button button-primary" href="/">Return to app</Link>
  </section></main>;
}
